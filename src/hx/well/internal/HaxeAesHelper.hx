package hx.well.internal;
import haxe.crypto.mode.Mode;
import haxe.io.Bytes;
import hx.well.facades.Environment;
import haxe.crypto.padding.Padding;
import haxe.crypto.Base64;
import haxe.crypto.Aes;
import haxe.crypto.Hmac;
import haxe.Exception;

class HaxeAesHelper {
    private static function generateIV():Bytes {
        var iv = Bytes.alloc(16);

        #if java
        // Native Secure Random Bytes for JVM
        new java.security.SecureRandom().nextBytes(cast iv.getData());
        #else
        // Generate IV
        // TODO: The IV (Initialization Vector) must be generated using a secure random number generator (PRNG).
        for(i in 0...iv.length)
            iv.set(i, Std.random(256));
        #end

        return iv;
    }

    public static function encrypt(bytes:Bytes):{iv: String, data: String, mac: String} {
        var key = Base64.decode(Environment.get("APP_KEY"));

        var iv = generateIV();

        var aes = new Aes();
        aes.init(key, iv);
        var encryptedData = aes.encrypt(Mode.CBC, bytes, Padding.PKCS7);
        var encryptedDataString = Base64.encode(encryptedData);
        var ivHex:String = iv.toHex();

        var hmac = new Hmac(SHA256);
        return {iv: ivHex, data: encryptedDataString, mac: hmac.make(key, Bytes.ofString(ivHex + encryptedDataString)).toHex()};
    }

    public static function decrypt(raw_iv: String, raw_data: String, raw_mac: String):String
    {
        var key = Base64.decode(Environment.get("APP_KEY"));

        var iv = Bytes.ofHex(raw_iv);
        var data = Base64.decode(raw_data);

        var hmac = new Hmac(SHA256);
        var expectedMac = hmac.make(key, Bytes.ofString(raw_iv + raw_data)).toHex();

        if (expectedMac != raw_mac) {
            throw new Exception("HMAC validation failed - data may be corrupted or tampered");
        }

        var aes = new Aes();
        aes.init(key, iv);

        var decryptedBytes = aes.decrypt(Mode.CBC, data, Padding.PKCS7);
        return decryptedBytes.toString();
    }
}
