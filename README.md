<div align="center">

# 🤖 Android_pwned

**A weekly, hands-on Android application security series.**
Two vulnerabilities a week. Every step documented. Every artifact published.

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Focus](https://img.shields.io/badge/focus-Android%20Pentesting-3DDC84)
![Framework](https://img.shields.io/badge/OWASP-MASVS%20%7C%20MASTG-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

</div>

---

## 📖 About

This repository documents my journey to sharpen my Android application security skills. Each week I take **two vulnerabilities** from a deliberately vulnerable app, exploit them end to end, and publish the full methodology, tooling, scripts, and evidence, so anyone can reproduce the work and learn from it.

- **Phase 1:** [Allsafe](https://github.com/t0thkr1s/allsafe) (native Android)
- **Phase 2:** DVMH / hybrid app testing (WebView, bridges, cross-platform frameworks)

Each write-up is also published as a LinkedIn post and a longer Medium article (links in the tracker below).

## ⚠️ Disclaimer

All testing is performed **only** against intentionally vulnerable applications that I run in my own lab. Nothing here should be used against systems or apps you do not own or have explicit written permission to test. The content is for **education and defensive purposes**. See [DISCLAIMER.md](DISCLAIMER.md).

## 🗺️ Roadmap & Progress Tracker

| Week | Vulnerabilities | MASVS Area | Write-up | LinkedIn | Medium | Status |
|:---:|---|---|---|---|---|:---:|
| 01 | Insecure Logging · Hardcoded Credentials | STORAGE / CRYPTO | [week-01](allsafe/week-01-logging-hardcoded-creds/) | – | – | ⬜ |
| 02 | Root Detection · Secure Flag Bypass | RESILIENCE / PLATFORM | [week-02](allsafe/week-02-root-detection-secure-flag/) | – | – | ⬜ |
| 03 | PIN Bypass · Certificate Pinning Bypass | AUTH / NETWORK | [week-03](allsafe/week-03-pin-bypass-cert-pinning/) | – | – | ⬜ |
| 04 | Insecure Broadcast Receiver · Insecure Service | PLATFORM | [week-04](allsafe/week-04-broadcast-service/) | – | – | ⬜ |
| 05 | Insecure Content Providers · Deep Link Exploitation | PLATFORM | [week-05](allsafe/week-05-providers-deeplinks/) | – | – | ⬜ |
| 06 | SQL Injection · Vulnerable WebView | CODE / PLATFORM | [week-06](allsafe/week-06-sqli-webview/) | – | – | ⬜ |
| 07 | Arbitrary Code Execution · Smali Patching | CODE / RESILIENCE | [week-07](allsafe/week-07-ace-smali/) | – | – | ⬜ |
| 08 | Native Library Analysis · Series Recap | CODE / RESILIENCE | [week-08](allsafe/week-08-native-recap/) | – | – | ⬜ |
| 09+ | DVMH hybrid app | TBD | [dvmh-hybrid](dvmh-hybrid/) | – | – | ⬜ |

> Legend: ⬜ planned · 🟨 in progress · ✅ published

## 🧰 Toolkit

| Category | Tools |
|---|---|
| Static analysis | jadx, apktool, MobSF, semgrep, grep/ripgrep |
| Dynamic instrumentation | Frida, objection, Magisk/rooted AVD |
| Traffic interception | Burp Suite, mitmproxy |
| Platform testing | adb, drozer, Android Studio / emulator |
| Reverse engineering | Ghidra, radare2, smali/baksmali, uber-apk-signer |

Full setup steps: [docs/lab-setup.md](docs/lab-setup.md)

## 🧭 Methodology

Every vulnerability follows the same repeatable flow, aligned with the [OWASP MASTG](https://mas.owasp.org/MASTG/) and [MASVS](https://mas.owasp.org/MASVS/):

1. **Recon**: understand the feature and its attack surface
2. **Static analysis**: decompile, read the code, locate the weakness
3. **Dynamic analysis**: confirm behaviour at runtime
4. **Exploitation**: build a working PoC
5. **Impact**: what an attacker gains in a real-world setting
6. **Remediation**: secure code and defence-in-depth fixes
7. **Artifacts**: scripts, hooks, payloads, screenshots

Details: [docs/methodology.md](docs/methodology.md)

## 📁 Repository Structure

```
Android_pwned/
├── README.md
├── DISCLAIMER.md
├── LICENSE
├── docs/
│   ├── lab-setup.md            # Environment & tooling setup
│   ├── methodology.md          # Testing flow + MASVS/MASTG mapping
│   ├── publishing-checklist.md # Pre-publish checks for each week
│   └── cheatsheet.md           # Quick adb / frida / objection commands
├── templates/                  # Write-up, LinkedIn, Medium templates
├── scripts/                    # Reusable helpers (new-week generator, etc.)
├── allsafe/
│   └── week-XX-<topic>/
│       ├── README.md           # Week overview
│       └── <vuln-name>/
│           ├── writeup.md      # Full technical write-up
│           ├── artifacts/      # Frida scripts, payloads, PoC code, patches
│           └── evidence/       # Screenshots, logs, recordings
└── dvmh-hybrid/                # Phase 2
```

## 📝 Write-up Format

Every vulnerability write-up uses [templates/writeup-template.md](templates/writeup-template.md): summary, severity, MASVS mapping, root cause, step-by-step exploitation, PoC, impact, remediation, and references.

## 🚀 Reproduce It Yourself

```bash
# 1. Get the target app (not redistributed here)
#    https://github.com/t0thkr1s/allsafe/releases

# 2. Set up your lab
#    see docs/lab-setup.md

# 3. Follow any week's write-up and artifacts
cd allsafe/week-01-logging-hardcoded-creds/
```

## 🤝 Contributing

Corrections, alternative approaches, and better payloads are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📣 Follow the Series

- LinkedIn: _add your profile link_
- Medium: _add your profile link_

## 📚 Credits & References

- [Allsafe](https://github.com/t0thkr1s/allsafe) by t0thkr1s
- [OWASP MASTG](https://mas.owasp.org/MASTG/) / [MASVS](https://mas.owasp.org/MASVS/)
- [Frida](https://frida.re/) · [objection](https://github.com/sensepost/objection) · [jadx](https://github.com/skylot/jadx)

## 📄 License

Original content in this repository is released under the [MIT License](LICENSE). Target applications remain the property of their respective authors and are **not** included here.
