package hx.well.internal;

import haxe.io.Bytes;
import hx.well.facades.Environment;
import haxe.Exception;

// PHP extern declarations
@:phpGlobal
extern class OpenSSL {
    @:native("openssl_encrypt")
    public static function encrypt(data:String, method:String, key:String, options:Int = 0, iv:String = ""):String;

    @:native("openssl_decrypt")
    public static function decrypt(data:String, method:String, key:String, options:Int = 0, iv:String = ""):String;

    @:native("openssl_random_pseudo_bytes")
    public static function randomPseudoBytes(length:Int):String;
}

class PhpAesHelper {
    private static inline var OPENSSL_RAW_DATA = 1;
    private static inline var AES_METHOD = "aes-256-cbc";

    private static function generateIV():String {
        // PHP'de güvenli IV üretimi
        return OpenSSL.randomPseudoBytes(16);
    }

    public static function encrypt(bytes:Bytes):{iv: String, data: String, mac: String} {
        var appKey = Environment.get("APP_KEY");
        var key = php.Global.base64_decode(appKey);

        var iv = generateIV();
        var ivHex = php.Global.bin2hex(iv);

        // AES-256-CBC ile şifreleme
        var encryptedData = OpenSSL.encrypt(
            bytes.toString(),
            AES_METHOD,
            key,
            OPENSSL_RAW_DATA,
            iv
        );

        var encryptedDataString = php.Global.base64_encode(encryptedData);

        // HMAC hesaplama
        var macData = ivHex + encryptedDataString;
        var mac = php.Global.hash_hmac("sha256", macData, key);

        return {
            iv: ivHex,
            data: encryptedDataString,
            mac: mac
        };
    }

    public static function decrypt(rawIv: String, rawData: String, rawMac: String):String {
        var appKey = Environment.get("APP_KEY");
        var key = php.Global.base64_decode(appKey);

        // HMAC doğrulama
        var macData = rawIv + rawData;
        var expectedMac = php.Global.hash_hmac("sha256", macData, key);

        if (expectedMac != rawMac) {
            throw new Exception("HMAC validation failed - data may be corrupted or tampered");
        }

        var iv = php.Global.hex2bin(rawIv);
        var encryptedData = php.Global.base64_decode(rawData);

        // AES-256-CBC ile çözme
        var decryptedData = OpenSSL.decrypt(
            encryptedData,
            AES_METHOD,
            key,
            OPENSSL_RAW_DATA,
            iv
        );

        if (decryptedData == null || decryptedData == "") {
            throw new Exception("Decryption failed - invalid data or key");
        }

        return decryptedData;
    }
}