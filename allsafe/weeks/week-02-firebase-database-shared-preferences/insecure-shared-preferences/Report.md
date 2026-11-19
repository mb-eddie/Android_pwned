# Mobile Application Security Assessment Report

## Insecure SharedPreferences — AllSafe (MASTG-TEST-0051)

**Application:** AllSafe (deliberately vulnerable Android app) · **Package:** `infosecadventures.allsafe` **Assessment Type:** Mobile Application Penetration Test **Standard:** OWASP MASVS v2 / MASTG **Date:** 2026-11-19 **Tester:** Android\_Pawned Series — Week 2, Day 4 **Difficulty:** Easy

---

## 1. Executive Summary

Challenge 01 of AllSafe demonstrates a plaintext credential storage vulnerability via Android SharedPreferences. A registration form accepts a username and password, then persists both values in cleartext inside `user.xml` under the app's private data directory. Any process or attacker with root access — or a malicious app on a rooted device — can read these credentials with a single file read. No decryption, no bypass, no tooling required.

**Overall Risk: HIGH** — Credentials exposed at rest on-device with no protection.

---

## 2. Scope and Test Environment

| Item | Detail |
| --- | --- |
| Target APK | allsafe.apk |
| Package name | infosecadventures.allsafe |
| Android version | 13 (LineageOS via Waydroid) |
| Root access | Yes — Waydroid shell |
| Static analysis | jadx-gui |
| Dynamic analysis | Waydroid shell + ADB |
| MASVS version | v2.0 |
| MASTG test | MASTG-TEST-0051 |

---

## 3. Finding — MASTG-TEST-0051: Plaintext Credential Storage in SharedPreferences

### 3.1 MASVS Mapping

| Field | Detail |
| --- | --- |
| **MASVS Control** | MASVS-STORAGE-1 |
| **Requirement** | The app does not store sensitive data (credentials, tokens, PII) where it can be read by other apps or the OS without authorization |
| **MASTG Test** | MASTG-TEST-0051 — Testing Local Storage for Sensitive Data |
| **OWASP Mobile Top 10** | M2 — Inadequate Supply Chain Security / M9 — Insecure Data Storage |
| **CWE** | CWE-312 — Cleartext Storage of Sensitive Information |
| **Severity** | HIGH |
| **Status** | Confirmed |

### 3.2 Description

Android SharedPreferences stores key-value pairs as plaintext XML files under `/data/data/<package>/shared_prefs/`. When the app calls `getSharedPreferences("user", 0)` with mode `0` (`MODE_PRIVATE`), only the app itself should be able to read the file under normal conditions. However, the data inside is **never encrypted** — the username and password are stored verbatim. On a rooted device or during a device compromise, these files are trivially readable by any privileged process, forensic tool, or attacker with physical access.

### 3.3 Static Analysis

The vulnerable code was identified in `infosecadventures.allsafe.challenges.InsecureSharedPreferences` via jadx-gui:

```java
SharedPreferences sharedpreferences = requireActivity().getSharedPreferences("user", 0);
SharedPreferences.Editor editor = sharedpreferences.edit();
editor.putString("username", username.getText().toString());
editor.putString("password", password.getText().toString());
editor.apply();
```

**Key observations:**

- `getSharedPreferences("user", 0)` — mode `0` = `MODE_PRIVATE`, correct file scoping
- `putString("password", ...)` — password written to storage with no hashing or encryption
- `editor.apply()` — asynchronously commits the plaintext credential to disk

A text search for `getSharedPreferences` in jadx returned 12 results across the codebase. The app's own class (`infosecadventures.allsafe.challenges.InsecureSharedPreferences`) is the only one storing user-supplied credentials. All other hits are Firebase SDK internals.

### 3.4 Dynamic Analysis — Test Steps

**Step 1:** Connect to the device with root via Waydroid shell:

```bash
sudo waydroid shell
# Results in :/ # (root shell)
```

**Step 2:** ADB shell (non-root) cannot access `/data/data` — confirms standard user isolation:

```bash
adb shell
waydroid:/data/data $ ls
ls: .: Permission denied
```

**Step 3:** Trigger the vulnerability — enter credentials in the app and tap \[STORE CREDENTIALS\]:

- Username: `Tester123`
- Password: `Pass123456`
- Toast confirms: \*"Successful registration!"

**Step 4:** Navigate to the app's SharedPreferences directory and list files:

```bash
cd /data/data/infosecadventures.allsafe/shared_prefs/
ls -la
```

```
total 16
drwxrwx--x 2 u0_a127 u0_a127 4096 2026-11-19 19:13 .
drwx------ 8 u0_a127 u0_a127 4096 2026-11-17 15:05 ..
-rw-rw---- 1 u0_a127 u0_a127 2115 2026-11-19 18:46 FirebaseHeartBeat[...].xml
-rw-rw---- 1 u0_a127 u0_a127  160 2026-11-19 19:13 user.xml
```

**Step 5:** Read the credential file:

```bash
cat user.xml
```

**Result:**

```xml
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="password">Pass123456</string>
    <string name="username">Tester123</string>
</map>
```

Username and password recovered in plaintext. No decryption. No tooling beyond a shell.

### 3.5 Evidence Summary

| Evidence | Detail |
| --- | --- |
| Vulnerable class | `InsecureSharedPreferences.lambda$onCreateView$0` |
| Storage file | `/data/data/infosecadventures.allsafe/shared_prefs/user.xml` |
| File permissions | `-rw-rw----` (owner + group read/write) |
| Data exposed | Username and password in plaintext XML |
| Access required | Root shell (Waydroid) or physical device access |
| Encryption applied | None |

### 3.6 Risk Rating

| Factor | Assessment |
| --- | --- |
| **Attack Vector** | Local (root or physical access required) |
| **Attack Complexity** | Low — single file read |
| **Privileges Required** | Root |
| **User Interaction** | None after credentials are stored |
| **Confidentiality Impact** | High — full credential exposure |
| **Integrity Impact** | Low |
| **Availability Impact** | None |
| **Overall Severity** | **HIGH** |

### 3.7 Remediation

**Primary fix — use EncryptedSharedPreferences (Jetpack Security):**

```kotlin
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val sharedPreferences = EncryptedSharedPreferences.create(
    context,
    "user",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)
```

**Additional controls:**

- Never store raw passwords at rest — store a salted hash (bcrypt / Argon2) if local verification is required, or store nothing and authenticate server-side
- Use Android Keystore for key management; keys never leave secure hardware
- Avoid `MODE_WORLD_READABLE` (deprecated since API 17 but still compiles)
- Apply certificate pinning and enforce authentication before any credential access

---

## 4. Remediation Summary

| # | Finding | Severity | MASVS Control | Recommendation |
| --- | --- | --- | --- | --- |
| 1 | Plaintext password in SharedPreferences | HIGH | MASVS-STORAGE-1 | Replace with EncryptedSharedPreferences; never store raw passwords |

