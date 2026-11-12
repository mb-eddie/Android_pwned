# Android Pawned — Day 2, Lab 2: Insecure Logging

Nov 12, 2026

## Executive Summary

Sensitive user input submitted through the AllSafe Insecure Logging activity was written in plaintext to the Android system log buffer via `Log.d()`. Any process with `READ_LOGS` permission, any attacker with ADB access, or any user on a rooted device can harvest this data trivially.

| Field | Detail |
| --- | --- |
| **Application** | AllSafe — `infosecadventures.allsafe` |
| **Platform** | Android 13, Waydroid emulator |
| **Vulnerability class** | Insecure Logging |
| **CWE** | CWE-532: Insertion of Sensitive Information into Log File |
| **OWASP Mobile Top 10** | M9: Insecure Data Storage (2024) |
| **Severity** | Medium |
| **Flag recovered** | `flag{i didn't find one}` |

## Environment & Toolset

| Component | Detail |
| --- | --- |
| **Host OS** | Linux (Wayland session, display `wayland-0`) |
| **Emulator** | Waydroid — Android 13 container |
| **Session user** | `redkite (1001)` |
| **Waydroid IP** | `192.168.240.112` |
| **ADB port** | `5555` (default, confirmed via `adb connect`) |
| **Target app** | AllSafe — `infosecadventures.allsafe` |
| **Tools used** | `waydroid`, `adb`, `logcat`, `ss` |

### Why ADB + logcat over `waydroid logcat`

Three log-collection methods are available in a Waydroid environment:

1. **`waydroid logcat`** — integrates with the Waydroid session directly
2. **`adb shell` + `logcat`** — routes through the ADB bridge at the container IP
3. **`waydroid logcat | grep`** — host-side filtering via sudo

This lab uses **method 2** (`adb shell` + `logcat`) for universal compatibility — the same commands reproduce on a physical device connected via USB or wireless ADB without modification.

## Reproduction Steps

### 1. Start the Waydroid session

```
waydroid session start
# [09:27:21] Starting waydroid session
# [09:27:38] Android with user 0 is ready
```

Confirm the session is running:

```
waydroid status
# Session:   RUNNING
# Container: RUNNING
# IP address: 192.168.240.112
```

### 2. Identify the ADB port

The default ADB port is 5555. Confirm with `ss`:

```
ss -tulnp | grep waydroid
```

The output shows UDP listeners on the `waydroid0` interface (DHCP/NTP) — no TCP 5555 listener exposed to the host, which is expected; Waydroid's ADB bridge is implicit at the container IP.

### 3. Connect ADB

```
adb connect 192.168.240.112:5555
# connected to 192.168.240.112:5555
```

### 4. Confirm AllSafe is installed

```
adb shell pm list packages | grep allsafe
# package:infosecadventures.allsafe
```

### 5. Launch the Insecure Logging activity

```
adb shell am start -n infosecadventures.allsafe/.ui.activities.InsecureLoggingActivity
```

### 6. Collect logs — Method A: file dump (system-wide)

From inside the ADB shell:

```
waydroid:/storage/emulated $ logcat > allsafelogs.txt
```

Pull to host:

```
adb pull /storage/emulated/allsafelogs.txt
# 1 file pulled — 69.5 MB/s (1,359,865 bytes in 0.019s)
```

### 7. Collect logs — Method B: filtered (AllSafe only)

```
adb pull /storage/emulated/allsafe_filtered_logs.txt
# 1 file pulled — 3.2 MB/s (4,217 bytes in 0.001s)
```

### 8. Collect logs — Method C: waydroid logcat (host-side)

```
sudo waydroid logcat | grep -i "allsafe" > waydroid_logs.txt
```

### 9. Live capture with targeted filter (the winning command)

Clear the buffer, then capture while interacting with the app:

```
adb logcat -c && adb logcat *:V | grep -iE "allsafe|flag|password|credit|user|secret|token"
```

Enter a secret in the AllSafe Insecure Logging UI and submit it. The plaintext value appears immediately in the terminal.

## Log Analysis & Evidence

### App lifecycle (from filtered logs)

| Timestamp | Event |
| --- | --- |
| `09:27:29` | `StorageManagerService` registers AllSafe package |
| `09:28:22` | `ActivityTaskManager` launches `MainActivity` |
| `09:28:22` | Process `1661:infosecadventures.allsafe/u0a127` started |
| `09:28:23` | `MainActivity` displayed — load time `+1s2ms` |
| `09:49:15` | `InsecureLoggingActivity` started (ADB intent, uid 2000) |

### Sensitive data leak (from live logcat capture)

After submitting input in the Insecure Logging activity, the following appeared three times in the log buffer within 17 seconds:

```
11-12 10:11:10.357  1661  1661 D ALLSAFE : User entered secret: flag{i didn't find one}
11-12 10:11:17.508  1661  1661 D ALLSAFE : User entered secret: flag{i didn't find one}
11-12 10:11:27.819  1661  1661 D ALLSAFE : User entered secret: flag{i didn't find one}
```

### Log entry breakdown

| Field | Value | Significance |
| --- | --- | --- |
| **Level** | `D` (Debug) | Should never appear in a production build |
| **Tag** | `ALLSAFE` | Developer-defined tag — `Log.d("ALLSAFE", …)` left in code |
| **Message** | `User entered secret: flag{i didn't find one}` | Full plaintext secret logged verbatim |
| **PID/TID** | `1661 / 1661` | Runs in the app's main thread |
| **Frequency** | 3× in 17 seconds | Fires on every submit event, not once |

### Key observation

The log tag is literally named `ALLSAFE` and the message prefix reads `User entered secret:` — the developer was aware they were logging a sensitive field, yet left the call in the codebase.

## Vulnerability Details

### Classification

| Standard | Reference |
| --- | --- |
| CWE | [CWE-532: Insertion of Sensitive Information into Log File](https://cwe.mitre.org/data/definitions/532.html) |
| OWASP Mobile Top 10 (2024) | M9: Insecure Data Storage |
| OWASP Mobile Testing Guide | MSTG-STORAGE-3: No sensitive data written to application logs |

### Root cause

The `InsecureLoggingActivity` calls `Log.d()` with user-supplied sensitive input directly in the string argument, with no guard on build type:

```java
// Vulnerable code (inferred from log output)
Log.d("ALLSAFE", "User entered secret: " + secretInput);
```

`Log.d()` writes to the global Android log buffer (`/dev/log/main`). This buffer persists in memory and is readable by any process granted `READ_LOGS` or by anyone with ADB shell access.

### Why Debug logs are dangerous in production

Android's `Log` class does not differentiate between debug and release builds at the API level. Unless the developer wraps calls in a `BuildConfig.DEBUG` check or strips them via ProGuard/R8, `Log.d()` calls ship to end users exactly as written.

## Impact Assessment

### Severity: Medium

Severity is contextual. In a real production app the data types being logged determine the actual risk:

| Logged data type | Real-world severity |
| --- | --- |
| Session tokens / auth tokens | High — direct account takeover |
| Passwords / PINs | High — credential theft |
| PII (name, email, phone) | Medium–High — GDPR/data breach exposure |
| Credit card numbers | Critical — PCI-DSS violation |
| Generic secrets (as in this lab) | Medium |

### Attack scenarios

1. **ADB access** — An attacker who physically accesses an unlocked device with USB debugging enabled runs `adb logcat` and dumps everything the app has logged. No root required.
2. **Malicious app with READ\_LOGS** — On Android < 4.1, any app could read the global log. On modern Android, `READ_LOGS` is a privileged permission, but malicious apps installed via side-loading may abuse it on rooted devices.
3. **Shared device / enterprise MDM** — An IT administrator or co-worker with device management access can pull logs from managed devices without the user's knowledge.
4. **Crash reporting tools** — Third-party SDKs (Firebase Crashlytics, Sentry) may capture logcat output during crash reports, transmitting sensitive data to external servers.

## Remediation

### Fix 1 — Guard with BuildConfig.DEBUG (minimum fix)

```java
// Before (vulnerable)
Log.d("ALLSAFE", "User entered secret: " + secretInput);

// After — debug builds only
if (BuildConfig.DEBUG) {
    Log.d("ALLSAFE", "User entered secret: " + secretInput);
}
```

This strips the log call from release APKs. Acceptable for non-sensitive debug info; not recommended when the data is sensitive at any build stage.

### Fix 2 — Remove the log call entirely (recommended)

```java
// Simply remove — there is no legitimate reason to log a user secret
// Log.d("ALLSAFE", "User entered secret: " + secretInput);  ← deleted
```

### Fix 3 — Use ProGuard / R8 to strip Log calls at build time

In `proguard-rules.pro`:

```
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
```

This removes all `Log.*` calls during the release build shrinking pass, even if developers forget to guard individual calls.

### Fix 4 — Use a logging wrapper library

Libraries like **Timber** (by Jake Wharton) plant a `DebugTree` only in debug builds and a no-op tree in release, enforcing safe logging by default:

```java
// Application class — debug build only plants logs
if (BuildConfig.DEBUG) {
    Timber.plant(new Timber.DebugTree());
}

// Usage — safe in both builds
Timber.d("Non-sensitive debug info only");
```

### Verification

After applying a fix, rebuild the release APK and confirm:

```
adb logcat -c && adb logcat *:V | grep -iE "allsafe|secret|password"
```

No output from the app after the fix = remediation confirmed.

## References

| Reference | Link |
| --- | --- |
| CWE-532: Insertion of Sensitive Information into Log File | [cwe.mitre.org/data/definitions/532](https://cwe.mitre.org/data/definitions/532.html) |
| OWASP Mobile Top 10 2024 — M9: Insecure Data Storage | [owasp.org/www-project-mobile-top-10](https://owasp.org/www-project-mobile-top-10/) |
| OWASP MSTG — MSTG-STORAGE-3 | [mobile-security.gitbook.io/masvs](https://mobile-security.gitbook.io/masvs/security-requirements/0x07-v2-data_storage_and_privacy_requirements) |
| Android Developer Docs — android.util.Log | [developer.android.com/reference/android/util/Log](https://developer.android.com/reference/android/util/Log) |
| Timber logging library | [github.com/JakeWharton/timber](https://github.com/JakeWharton/timber) |
| AllSafe — intentionally vulnerable Android app | [github.com/t0thkr1s/allsafe](https://github.com/t0thkr1s/allsafe) |
| Waydroid documentation | [docs.waydro.id](https://docs.waydro.id) |
