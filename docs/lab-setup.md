# Lab Setup

## Hardware / OS
- Host: Linux or macOS recommended (Windows works with WSL for CLI tools)
- Target: Android Studio AVD (**Google APIs image, not Play Store**, so root is possible) or a dedicated rooted test device

## Core tooling
```bash
# Android platform tools
sudo apt install adb          # or via Android SDK

# Python tooling
pipx install frida-tools
pipx install objection
pipx install apkleaks
pipx install mitmproxy

# Static analysis
# jadx:    https://github.com/skylot/jadx/releases
# apktool: https://apktool.org/
# MobSF:   docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf
```

## Frida server on the device
```bash
adb shell getprop ro.product.cpu.abi            # identify architecture
# download matching frida-server from https://github.com/frida/frida/releases
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "su -c /data/local/tmp/frida-server &"
frida-ps -U                                      # verify
```
Keep the frida-server version aligned with `frida --version` on the host.

## Burp Suite proxy
1. Burp listener on all interfaces (e.g. 8080)
2. Device Wi-Fi proxy → host IP:8080
3. Install Burp CA as a **system** certificate (Android 7+ ignores user CAs by default)
4. For the emulator: `adb reverse` or `emulator -http-proxy`

## Target app
Download Allsafe from the upstream releases page and install:
```bash
adb install allsafe.apk
```

## Snapshot your AVD
Take a clean snapshot before every week so you can reset state quickly.

## Sanity checklist
- [ ] `adb devices` shows the device
- [ ] `frida-ps -U` lists processes
- [ ] Burp intercepts non-pinned traffic
- [ ] jadx opens the APK
- [ ] AVD snapshot saved
