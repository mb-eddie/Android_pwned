# Quick Reference

## adb
```bash
adb devices
adb install app.apk
adb shell pm list packages | grep <name>
adb shell pm path <package>
adb pull <path> .
adb logcat --pid=$(adb shell pidof -s <package>)
adb shell am start -n <package>/<activity>
adb shell am start -a android.intent.action.VIEW -d "<scheme>://<host>/<path>"
adb shell am broadcast -a <action> --es key value
adb shell content query --uri content://<authority>/<path>
```

## Static
```bash
jadx -d jadx-out app.apk
apktool d app.apk -o apktool-out
apktool b apktool-out -o patched.apk
# re-sign before install (e.g. uber-apk-signer)
```

## Frida
```bash
frida-ps -Uai
frida -U -f <package> -l hook.js
frida -U -n <package> -l hook.js
frida-trace -U -f <package> -j '*!*onCreate*'
```

## objection
```bash
objection -g <package> explore
android sslpinning disable
android root disable
android hooking list activities
android hooking watch class_method <class.method> --dump-args --dump-return
```

## drozer
```bash
run app.package.attacksurface <package>
run app.activity.info -a <package>
run app.provider.info -a <package>
run scanner.provider.injection -a <package>
```
