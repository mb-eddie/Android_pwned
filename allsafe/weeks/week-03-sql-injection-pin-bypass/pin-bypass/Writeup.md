# PIN Bypass — Hardcoded Credential & Runtime Hook

| | |
|---|---|
| **App** | Allsafe v1.0 (infosecadventures.allsafe) |
| **Week** | 03 / Day 06 |
| **Category** | Insecure Local Authentication |
| **MASVS** | MASVS-AUTH-2 |
| **MASTG** | MASTG-TEST-0018 |
| **Severity** | 🔴 Critical — full authentication bypass via static analysis or runtime instrumentation |
| **Android / device** | Android 11 (Waydroid on Kali Linux), unrooted userspace / root via waydroid shell |
| **Tool versions** | jadx-gui 1.5.x, frida 17.27.6, frida-tools 14.13.2, adb (Platform Tools) |

---

## 1. Summary

The Allsafe PIN Bypass challenge implements a 4-digit PIN validation routine that stores the correct PIN as a hardcoded Base64-encoded string inside the application binary. An attacker can recover the PIN in under 10 seconds via static analysis alone, bypass validation entirely by hooking the return value with Frida, or enumerate the full 4-digit keyspace (0000–9999) programmatically via Frida brute force — all without network access, root, or special device privileges.

---

## 2. Background

Hardcoded credentials in mobile applications are one of the most prevalent and easily exploitable vulnerability classes in Android security. When a developer embeds a secret — a PIN, password, API key, or token — directly in the application binary, that secret is accessible to anyone who decompiles the APK. Encoding the value (Base64, hex) provides no meaningful protection; it is obfuscation, not encryption.

Independently of static discovery, Frida — a dynamic instrumentation framework — allows an attacker to attach to a running Android process, intercept any method at runtime, and override its behaviour or return value. This makes client-side authentication logic inherently untrustworthy: even if the secret were genuinely unknown, the validation function itself can be forced to return `true` regardless of input.

The challenge demonstrates two distinct attack surfaces that exist in production apps:

- **Static:** Any secret embedded in the binary can be extracted by decompiling the APK
- **Dynamic:** Any client-side boolean gate can be bypassed with a 5-line Frida script

---

## 3. Recon

The challenge presents a **PIN VALIDATION** screen with a single `EditText` field and a `[VALIDATE]` button. The description explicitly states: *"Locate the method in the code and use Frida to override the return value. You can even brute-force the code because it's only 4 digit."*

**Relevant component:** `infosecadventures.allsafe.challenges.PinBypass` (Fragment)

No exported components, no network calls, no special permissions required. The entire attack surface is the UI input field and the local validation method — both accessible to any user with the app installed.

**ADB connection:**
```bash
adb connect 192.168.240.112:5555
# connected to 192.168.240.112:5555
```

---

## 4. Static Analysis

**Decompile the APK:**
```bash
jadx-gui allsafe.apk
# Navigate: infosecadventures → allsafe → challenges → PinBypass
```

### 4.1 The Validation Method

```java
// PinBypass.kt (decompiled) — checkPin()
private final boolean checkPin(String pin) {
    byte[] bArrDecode = Base64.decode("NDg2Mw==", 0);   // ← hardcoded Base64 PIN
    Intrinsics.checkNotNullExpressionValue(bArrDecode, "decode(...)");
    return Intrinsics.areEqual(pin, new String(bArrDecode, Charsets.UTF_8));
}
```

**Why this is vulnerable:** The correct PIN is stored as a Base64 string directly in the method body. Base64 is a reversible encoding — it provides zero confidentiality. Any decompiler exposes it immediately.

### 4.2 Static PIN Recovery

```bash
echo "NDg2Mw==" | base64 -d
# → 4863
```

PIN recovered: **`4863`**

> **Note:** During testing, `echo "NDg2Mw=" | base64 -d` (single `=`) returned `invalid input`. The correct string requires the full double padding `NDg2Mw==`. Always copy the exact string from JADX without modification.

### 4.3 The Button Handler

```java
// onCreateView$lambda$0 — VALIDATE button click
public static final void onCreateView$lambda$0(EditText $pin, PinBypass this$0, View it) {
    if (($pin.getText().toString().length() == 0) || !this$0.checkPin($pin.getText().toString())) {
        // ← calls checkPin() — our hook target
        snackUtil.simpleMessage(fragmentActivity, "Incorrect PIN, try harder!");
        return;
    }
    snackUtil.simpleMessage(fragmentActivity, "Access granted, good job!");
}
```

**Source → Sink data flow:**

```
SOURCE: EditText.getText().toString()     ← raw PIN input
         ↓
         checkPin(pin)
         ↓  Base64.decode("NDg2Mw==") → "4863"
SINK:   Intrinsics.areEqual(pin, "4863") ← comparison — our hook point
         ↓
         true  → "Access granted, good job!"
         false → "Incorrect PIN, try harder!"
```

---

## 5. Dynamic Analysis

### 5.1 Frida Setup

**Install frida-tools on Kali:**
```bash
python3 -m venv Android_pwned
source Android_pwned/bin/activate
pip install frida-tools
frida --version
# 17.27.6
```

**Determine device architecture:**
```bash
adb shell getprop ro.product.cpu.abi
# x86_64
```

**Download matching frida-server** (version must match `frida --version` exactly):
```bash
wget https://github.com/frida/frida/releases/download/17.27.6/frida-server-17.27.6-android-x86_64.xz
xz -d frida-server-17.27.6-android-x86_64.xz
mv frida-server-17.27.6-android-x86_64 frida-server
```

**Push and start on device:**
```bash
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server

# IMPORTANT: must start from waydroid shell (root) — adb shell is non-root
waydroid shell
/data/local/tmp/frida-server &
```

> **Troubleshooting note:** Starting frida-server via `adb shell` resulted in `Failed to attach: unable to access process` errors — even when targeting by PID (`-p`) or process name (`-n`). The root cause is that `adb shell` on Waydroid runs as a non-privileged user. `waydroid shell` is root by default and resolves the permission issue. Additionally, `-f` (spawn mode) caused timeout failures on this environment; `-n` (attach by name) with the server running as root was the reliable approach.

**Verify connection:**
```bash
frida-ps -U | grep -i allsafe
# 1803  Allsafe
```

---

## 6. Exploitation

### Attack Path 1 — Static Decode (No Tools Runtime)

1. Decompile APK in JADX-GUI, navigate to `PinBypass.checkPin()`
2. Extract the Base64 string: `NDg2Mw==`
3. Decode on Kali: `echo "NDg2Mw==" | base64 -d` → `4863`
4. Enter `4863` in the PIN field → tap [VALIDATE]
5. Result: **"Access granted, good job!"**

### Attack Path 2 — Frida Return Value Override

**Script: `pin_override.js`**
```javascript
Java.perform(function () {

    var PinBypass = Java.use("infosecadventures.allsafe.challenges.PinBypass");

    PinBypass.checkPin.implementation = function (pin) {
        console.log("[*] checkPin() intercepted → input was: " + pin);
        console.log("[*] Forcing return value: true");
        return true;   // bypass — always grant access
    };

    console.log("[*] Hook armed — enter any 4 digits and tap VALIDATE");
});
```

```bash
frida -U -n "Allsafe" -l pin_override.js
```

**Runtime output:**
```
[*] Hook armed — enter any 4 digits and tap VALIDATE
[WayDroid x86 64 Device::Allsafe ]-> [*] checkPin() intercepted → input was: 1234
[*] Forcing return value: true
```

Enter any 4-digit value → tap [VALIDATE] → **"Access granted, good job!"**

This bypasses authentication entirely without knowing the PIN. The correct value is irrelevant.

### Attack Path 3 — Frida Brute Force (PIN Discovery)

The brute force requires a live instance of `PinBypass` to call the instance method `checkPin()`. The approach hooks the method on first call, captures `this`, then iterates 0000–9999 from within the hook.

**Script: `pin_bruteforce.js`**
```javascript
Java.perform(function () {

    var PinBypass = Java.use("infosecadventures.allsafe.challenges.PinBypass");

    PinBypass.checkPin.implementation = function (pin) {
        var instance = this;

        console.log("[*] Instance captured — starting brute force...");

        for (var i = 0; i <= 9999; i++) {
            var candidate = ("0000" + i).slice(-4);
            var result = instance.checkPin(candidate);
            if (result) {
                console.log("[+] ✅ CORRECT PIN FOUND: " + candidate);
                break;
            }
        }

        return true;  // grant access after discovery
    };

    console.log("[*] Hook armed — enter any 4 digits and tap VALIDATE to trigger brute force");
});
```

```bash
frida -U -n "Allsafe" -l pin_bruteforce.js
```

**Runtime output:**
```
[*] Hook armed — enter any 4 digits and tap VALIDATE to trigger brute force
[WayDroid x86 64 Device::Allsafe ]-> [*] Instance captured — starting brute force...
[+] ✅ CORRECT PIN FOUND: 4863
```

> **Failure documented:** The first brute force attempt called `PinBypass.checkPin(candidate)` as a static method without an instance, producing `Error: checkPin: cannot call instance method without an instance`. The fix was to capture `this` inside the hooked implementation and call `instance.checkPin(candidate)` instead.

### Proof of Concept

```
Attack 1 — Static:   echo "NDg2Mw==" | base64 -d → 4863 → enter manually → "Access granted"
Attack 2 — Override: frida -U -n "Allsafe" -l pin_override.js → input: 1234 → "Access granted"
Attack 3 — Bruteforce: frida -U -n "Allsafe" -l pin_bruteforce.js → PIN FOUND: 4863
```

📸 Evidence: `evidence/`
- `01-jadx-pinbypass-source.png` — JADX decompiled checkPin method
- `02-frida-override-console.png` — Frida hook intercepting and forcing true
- `03-access-granted-override.png` — App showing "Access granted" with wrong PIN
- `04-bruteforce-console.png` — Frida brute force discovering PIN 4863
- `05-access-granted-bruteforce.png` — App showing "Access granted" post-bruteforce

---

## 7. Impact

In a production Android application, this vulnerability class has the following real-world consequences:

**Complete authentication bypass:** Any user with the APK can recover the PIN in seconds via static analysis, without ever running the app. JADX is free, widely available, and requires no special skills.

**Runtime bypass without knowledge of the secret:** Even if the PIN were genuinely unknown (stored server-side, derived at runtime), Frida's return value override makes the validation function irrelevant. Client-side authentication gates cannot be trusted.

**Applies beyond PINs:** The same pattern is used in production apps for license checks (`isLicensed()`), premium feature gates (`isPremiumUser()`), certificate pinning (`checkServerTrusted()`), and root detection (`isRooted()`). All are bypassable with the same technique.

**No privileged access required:** On Waydroid (and many real devices), frida-server can be started with user-level root on a rooted device, or via ADB on a debuggable build. The attacker needs only a USB cable and a laptop.

**Affected parties:** Every user of an application relying on client-side PIN or credential validation for access control.

---

## 8. Remediation

### Primary Fix — Never Embed Secrets in the Binary

```kotlin
// ❌ VULNERABLE — secret in binary
private fun checkPin(pin: String): Boolean {
    val decoded = Base64.decode("NDg2Mw==", Base64.DEFAULT)
    return pin == String(decoded, Charsets.UTF_8)
}

// ✅ SECURE — PIN derived from server-side challenge or stored in Android Keystore
private fun checkPin(pin: String): Boolean {
    val storedHash = secureStorage.getPinHash()     // from Android Keystore / server
    val inputHash  = Argon2.hash(pin, storedHash.salt)
    return inputHash.value == storedHash.value
}
```

### Defence in Depth

- **Move authentication server-side:** PIN validation should be performed on a backend server over TLS, not on the device. The device submits the PIN; the server responds with a session token on success. The correct PIN never exists on the device.
- **Android Keystore for local secrets:** If offline PIN validation is required (e.g., biometric fallback), store derived key material in the Android Keystore system — it is hardware-backed and inaccessible to decompilers.
- **Anti-tampering / runtime integrity checks:** Use Google Play Integrity API or SafetyNet (deprecated but instructive) to detect instrumented environments. These add friction but do not eliminate the threat.
- **Replace Base64 with real hashing:** If a PIN must be stored locally, store a salted hash (Argon2, bcrypt) — never the PIN or a reversible encoding of it.

### Verifying the Fix

```bash
# Attempt static recovery — should yield no plaintext PIN
jadx-gui allsafe.apk
# Search for: Base64, decode, "==", hardcoded string literals near checkPin

# Attempt Frida override — observe: app still fails without server confirmation
frida -U -n "Allsafe" -l pin_override.js
# Input any PIN → server rejects → no access granted
```

---

## 9. Detection / Testing Notes

**Manual static analysis:**
- Decompile APK with JADX; search for `Base64.decode`, `equals`, `compareTo`, `areEqual` near authentication methods
- Search for string literals matching `[A-Za-z0-9+/]+=*` (Base64 pattern) in method bodies
- MobSF flags hardcoded strings in authentication contexts automatically

**Frida detection approach (for pentesters):**
- Hook `checkPin` or equivalent boolean method; log inputs and return values
- Override return value to `true`; observe if access is granted without server round-trip
- If yes: client-side auth is confirmed; file as Critical

**SAST tools:**
- MobSF: flags `Base64.decode` in authentication methods
- Semgrep rule: `android.security.hardcoded-credentials`
- CodeQL: taint from `Base64.decode` → `String.equals` in auth context

**Frida detection hook (generic auth bypass test):**
```javascript
// Generic: hook any boolean method and log/override
Java.enumerateMethods("*!check*,*!validate*,*!verify*,*!isValid*").forEach(function(c) {
    c.classes.forEach(function(cls) {
        cls.methods.forEach(function(method) {
            console.log("[Enum] " + cls.name + "." + method.name);
        });
    });
});
```

---

## 10. References

- **OWASP MASTG:** [MASTG-TEST-0018 — Testing Local Authentication](https://mas.owasp.org/MASTG/tests/android/MASVS-AUTH/MASTG-TEST-0018/)
- **OWASP MASVS:** [MASVS-AUTH-2](https://mas.owasp.org/MASVS/controls/MASVS-AUTH-2/)
- **OWASP Mobile Top 10:** [M2 — Insecure Data Storage](https://owasp.org/www-project-mobile-top-10/)
- **Frida Documentation:** [frida.re/docs/javascript-api](https://frida.re/docs/javascript-api/)
- **Allsafe:** [github.com/t0thkr1s/allsafe](https://github.com/t0thkr1s/allsafe)
- **Android Keystore:** [developer.android.com/training/articles/keystore](https://developer.android.com/training/articles/keystore)
- **Google Play Integrity API:** [developer.android.com/google/play/integrity](https://developer.android.com/google/play/integrity)
