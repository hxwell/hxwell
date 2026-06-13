package cases;

import utest.Assert;
import hx.well.facades.Crypt;
import hx.well.facades.Environment;
import haxe.crypto.Base64;
import haxe.io.Bytes;

class TestCrypt extends utest.Test {
    function setup() {
        Environment.reset();
        Environment.set("APP_KEY", Base64.encode(Bytes.ofString("0123456789abcdef0123456789abcdef")));
    }

    function testStringRoundTrip() {
        var encrypted = Crypt.encryptString("merhaba dünya");
        Assert.notEquals("merhaba dünya", encrypted);
        Assert.equals("merhaba dünya", Crypt.decryptString(encrypted));
    }

    function testObjectRoundTrip() {
        var encrypted = Crypt.encrypt({name: "baris", n: 7}, true);
        var decrypted:{name:String, n:Int} = Crypt.decrypt(encrypted);
        Assert.equals("baris", decrypted.name);
        Assert.equals(7, decrypted.n);
    }

    function testDifferentCiphertextSamePlaintext() {
        var first = Crypt.encryptString("data");
        var second = Crypt.encryptString("data");
        Assert.equals(Crypt.decryptString(first), Crypt.decryptString(second));
    }
}
