# Allsafe Week 1: Hardcoded Credentials and Embedded Secrets

## Assessment summary

| Field | Value |
|---|---|
| Application | Allsafe 1.5 (as shown in the supplied manifest screenshot) |
| Package | `infosecadventures.allsafe` |
| Assessment type | Static analysis of an intentionally vulnerable training app, with lab UI inspection |
| Focus | Hardcoded credentials and embedded secret-like configuration |
| Analysis tools | JADX GUI, Apktool, `regbait`, VS Code search; Waydroid for the lab app UI |
| Status | Secret-like values and the challenge screen were identified. The actual challenge credential pair and successful login were not recorded in the supplied evidence. |
| Severity | No independent severity assigned. Scanner labels below are reproduced as tool output, not validated impact ratings. |

> **Scope:** Perform this work only on Allsafe or another application you own or are explicitly authorized to assess. Do not test any discovered value against external services. This report intentionally redacts credentials, keys, and complete client identifiers.

## 1. Objective and context

The Allsafe Week 1 challenge is titled **Hardcoded Credentials**. Its on-screen briefing says that two username/password combinations are embedded in the challenge and asks the learner to find them. The screenshots document opening the APK in JADX, reviewing its manifest, launching Allsafe in a Waydroid lab, navigating to the challenge, and searching for `login` in JADX.

The supplied notes also describe using `regbait`, a custom Go-based secret-finding tool, before manually inspecting the APK. The reported scan identified several secret-like resource values and a credential-looking URL. These are useful leads; scanner output by itself does not establish that each value is a usable secret or that a challenge login succeeded.

## 2. Scope and environment

- **Target source:** Allsafe APK from the [upstream releases page](https://github.com/t0thkr1s/allsafe/releases/latest).
- **Static analysis:** JADX GUI and Apktool.
- **Secret scan:** [`regbait`](https://github.com/mb-eddie/regbait), described in the notes as a custom Go tool for finding secrets, credentials, and API keys in decoded APK content.
- **Code search:** VS Code workspace search, with Copilot used as an assistant to help identify interesting code. Treat suggestions as leads and confirm them in the source.
- **Lab UI:** Waydroid. The notes record starting a Waydroid session and waiting for Android user 0 to become ready. See the [Waydroid project](https://waydro.id/) and [GitHub repository](https://github.com/waydroid/waydroid).
- **APK details visible in supplied evidence:** Allsafe version 1.5; package `infosecadventures.allsafe`.
- **Not recorded:** APK SHA-256, exact JADX/Apktool/`regbait` versions, Android image/version, or a successful challenge login.

The APK is not included in this repository. For static inspection alone, installation is not required.

## 3. Reproduction workflow

### 3.1 Obtain and decode the APK

Download Allsafe from its upstream release source, then record the sample hash locally:

```bash
sha256sum allsafe.apk
```

Decode with Apktool:

```bash
apktool d allsafe.apk -o allsafe-decoded
```

The original notes recorded Apktool decoding the manifest, resources, DEX/smali files, assets, libraries, and other APK contents. Tool output and version were not preserved, so capture them in a future run.

### 3.2 Run `regbait`

The original notes ran the custom scanner against the decoded tree:

```bash
./regbait /path/to/allsafe-decoded
```

The recorded scan reported:

- **13,123 files scanned** (126.7 MB) in 10.463 seconds
- **256 skipped**, **0 errors**
- **5 findings total**: 1 CRITICAL, 2 HIGH, 1 MEDIUM, and 1 LOW according to `regbait`
- Two identical secret-like values were collapsed across duplicate locations

These are the scanner's classifications and counts for that run, not a severity assessment independently confirmed by this report. Re-run the tool against the exact APK under review; results can differ by sample and tool version.

### 3.3 Inspect the APK with JADX GUI

1. Open JADX GUI and select the authorized `allsafe.apk`.
2. Wait for decompilation. Inspect `AndroidManifest.xml` for package, version, permissions, and components. The supplied screenshot shows version 1.5 and package `infosecadventures.allsafe`.
3. Open **Text Search** and enable searches across **Class**, **Method**, **Field**, **Code**, **Resource**, and **Comments**. Include text resources; start without binary-resource search to reduce noise.
4. Search the challenge and authentication vocabulary below. Search one term at a time, inspect the matching context, and follow references to the code that consumes the value.
5. Compare suspicious locations with the `regbait` output. Record the source file, line, field/method, and use site. Do not copy complete secrets into the report.

#### Useful JADX search terms

| Search area | Literal terms to try |
|---|---|
| Challenge/authentication flow | `Hardcoded Credentials`, `HARDcoded`, `challenge`, `login`, `authenticate`, `credential` |
| User identifiers | `username`, `user_name`, `user`, `email`, `account` |
| Passwords and secrets | `password`, `passwd`, `pwd`, `passphrase`, `secret` |
| Tokens and API configuration | `api_key`, `apiKey`, `apikey`, `client_secret`, `access_token`, `refresh_token`, `token` |
| Headers and endpoints | `Authorization`, `Basic `, `Bearer `, `https://` |
| Resource names seen in the scan | `dev_env`, `default_web_client_id`, `google_api_key`, `firebase_database_url` |
| Value-handling APIs | `SharedPreferences`, `getString`, `putString`, `Base64.decode`, `BuildConfig` |

If the JADX version provides regex mode, try these patterns as a starting point:

```regex
(?i)(password|passwd|pwd|passphrase|secret)
(?i)(username|user[_-]?name|login|credential|account)
(?i)(api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token)
(?i)(authorization|bearer|basic)
```

Regex support varies by JADX version. If a pattern does not work, search its terms separately. Broad searches generate false positives; verify each match in its surrounding code.

#### Other useful locations

- `res/values/strings.xml` and localized resource directories
- `assets/` and `res/raw/` configuration files
- Decompiled Java/Kotlin source and DEX string references
- Smali files when decompiled source obscures the value or use
- The manifest for app identity and attack-surface context

### 3.4 Search in VS Code

VS Code workspace search can find the same terms across Apktool output. Search `res/`, `assets/`, `smali*/`, and decompiled source separately when the result set is large. Copilot can help explain surrounding code or suggest follow-up terms, but it does not verify a secret: check every suggestion against the source and the authorized lab behavior.

### 3.5 Inspect the challenge in Waydroid

The supplied screenshots show Allsafe installed and launched in a Waydroid Android environment, followed by the vulnerability menu and the **Hardcoded Credentials** challenge. The notes say static analysis did not initially require installing the app; the emulator was used to inspect the challenge and record progress. A challenge screen is context, not proof that extracted credentials were accepted.

## 4. Scanner results and manual interpretation

The `regbait` output in the supplied notes reported the following sanitized results. Raw values are deliberately omitted.

| Tool severity | Rule / finding | Reported location | Interpretation and follow-up |
|---|---|---|---|
| CRITICAL | `basic-auth-url` — credentials embedded in a URL | `res/values/strings.xml:71:28`, resource `dev_env` | A credential-looking URL was reported. Inspect the resource and its use in the local lab; do not reuse or test its credentials against an external service. |
| HIGH | `android-strings-xml-secret` — secret-named default-locale resource | `res/values/strings.xml:69:42`, resource `default_web_client_id` | The scanner flags the resource name/value as secret-like. A client ID may be public configuration; confirm whether any private credential is actually present. |
| HIGH | `google-api-key` — Google API-key-like value | `res/values/strings.xml:82:35`; duplicate at line 84 | A key-like value was found. Its permissions, restrictions, and impact were not validated. Do not call external services with it. |
| MEDIUM | `firebase-database-url` | `res/values/strings.xml:80:42`, resource `firebase_database_url` | The URL identifies a Firebase database endpoint; the URL alone does not prove that data is exposed. |
| LOW | `smali-const-string-secret` | `smali_classes7/com/google/crypto/tink/aead/AesGcmSivKeyManager.smali:91:23`; duplicate in Tink smali | The reported string is an AES/GCM-SIV algorithm/mode name, not a secret. This is a likely false positive. |

The recorded summary listed one result per rule and five results total, with two identical values collapsed across locations. The values and their contexts were masked in this report to avoid redistributing credentials or key-like material.

### Challenge credential status

The challenge briefing states that two username/password combinations are embedded, and the original notes say the scanner had already surfaced secrets before the manual JADX pass. However, the saved scanner excerpt identifies a credential-looking URL and configuration candidates; it does not include two clearly identified username/password pairs, their source locations, or evidence of a successful challenge login. The supplied JADX screenshot shows a broad `login` search with many results, not the credential strings themselves.

Therefore, the scan successfully surfaced secret-like material and useful leads, but the pair and successful authentication are **not independently evidenced in the materials currently available**. To complete that part of the write-up, record the relevant class/resource and line, redact the values, trace how the app checks them, and capture the result of a challenge-only login in the local Allsafe lab.

## 5. Evidence

Screenshots are stored under `evidence/`:

| File | Captured step |
|---|---|
| `01-jadx-start.png` | JADX GUI start screen |
| `02-open-allsafe-apk.png` | Selecting the APK |
| `03-manifest-review.png` | Manifest and package/version review |
| `04-android-app-launcher.png` | Allsafe in the Android app launcher |
| `05-allsafe-home.png` | Allsafe landing screen |
| `06-vulnerability-menu.png` | Vulnerability module list |
| `07-hardcoded-credentials-challenge.png` | Challenge briefing |
| `08-jadx-text-search-login.png` | JADX search for `login`; search configuration and noisy results |

The screenshots show workflow and target context. They do not expose the scanner output or prove a successful credential check. For a final reproducibility record, add a sanitized `regbait` output excerpt, tool versions, Android version, APK hash, exact code locations, and challenge-only validation evidence.

## 6. Impact and severity

An embedded server-side password or unrestricted key can be extracted from an APK and may permit unauthorized access. The actual impact depends on the value's purpose, privileges, restrictions, and reachable service. A client identifier or database URL alone is not proof of a vulnerability.

No CVSS score or independent severity is assigned here because the supplied evidence does not establish the challenge credential pair, external service impact, or successful authentication. The CRITICAL/HIGH/MEDIUM/LOW labels above are the scanner's labels for this training APK; they should not be presented as confirmed production severity.

## 7. Remediation

- Keep server-side passwords, private API keys, signing keys, and privileged tokens out of distributed APKs.
- Move privileged operations to a server and enforce authorization there.
- Restrict public client keys to the required APIs and app identity; monitor quotas and rotate exposed keys.
- Rotate any genuine credentials that were distributed and review their access history.
- Do not rely on obfuscation, `BuildConfig`, resource naming, or Base64 encoding to protect secrets.
- Use short-lived, least-privilege tokens and platform-appropriate secure storage for user session material.

## 8. Retest criteria

- No server-side credential or private key remains in the APK, resources, assets, or DEX strings.
- Any public client configuration is appropriately restricted.
- Previously exposed credentials have been rotated and are no longer valid.
- Authentication and authorization are enforced by the service rather than a client-side constant.
- A repeat static review and authorized challenge-only test confirm the remediation.

## 9. References

- [Allsafe releases](https://github.com/t0thkr1s/allsafe/releases/latest)
- [`regbait` custom scanner](https://github.com/mb-eddie/regbait)
- [JADX](https://github.com/skylot/jadx)
- [Apktool](https://apktool.org/)
- [Waydroid](https://github.com/waydroid/waydroid)
- [OWASP MASVS](https://mas.owasp.org/MASVS/)
- [OWASP MASTG](https://mas.owasp.org/MASTG/)
- [Android security tips](https://developer.android.com/privacy-and-security/security-tips)
