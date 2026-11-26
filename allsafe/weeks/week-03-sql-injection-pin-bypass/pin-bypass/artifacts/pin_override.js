Java.perform(function () {

    var PinBypass = Java.use("infosecadventures.allsafe.challenges.PinBypass");

    PinBypass.checkPin.implementation = function (pin) {
        console.log("[*] checkPin() intercepted → input was: " + pin);
        console.log("[*] Forcing return value: true");
        return true;
    };

    console.log("[*] Hook armed — enter any 4 digits and tap VALIDATE");
});
