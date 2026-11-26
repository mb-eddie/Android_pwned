Java.perform(function () {

    var PinBypass = Java.use("infosecadventures.allsafe.challenges.PinBypass");

    // Override checkPin to intercept the instance when app calls it
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

        // Still return true so the app shows "Access granted"
        return true;
    };

    console.log("[*] Hook armed — enter any 4 digits and tap VALIDATE to trigger brute force");
});
