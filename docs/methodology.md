# Methodology

Aligned with OWASP MASTG test cases and MASVS control groups.

## Flow per vulnerability
| Phase | Goal | Typical tools |
|---|---|---|
| 1. Recon | Understand the feature, screens, permissions, exported components | `aapt`, `adb`, manifest review |
| 2. Static | Find the weakness in code/resources | jadx, apktool, MobSF, grep |
| 3. Dynamic | Observe runtime behaviour | Frida, objection, logcat, Burp |
| 4. Exploit | Reliable PoC | Frida scripts, adb intents, patched APK |
| 5. Impact | Realistic attacker value | Threat modelling |
| 6. Fix | Secure code + defence in depth | Code diff, config changes |

## MASVS v2 control groups used in this series
- **MASVS-STORAGE**: data at rest, logs, backups
- **MASVS-CRYPTO**: keys, hardcoded secrets, algorithms
- **MASVS-AUTH**: authentication and local auth
- **MASVS-NETWORK**: TLS, pinning
- **MASVS-PLATFORM**: IPC, WebViews, deep links, components
- **MASVS-CODE**: input handling, code quality, dynamic loading
- **MASVS-RESILIENCE**: root detection, tamper resistance, obfuscation

## Evidence standards
- Screenshot or short recording for every successful exploit
- Commands copy-pasteable and tested on a clean snapshot
- Record tool versions and Android version in each write-up
- Redact anything personal (IPs, tokens, device serials)
