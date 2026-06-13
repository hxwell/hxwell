package hx.well.internal;
import haxe.crypto.mode.Mode;
import haxe.io.Bytes;
import hx.well.facades.Environment;
import haxe.crypto.padding.Padding;
import haxe.crypto.Base64;
import haxe.crypto.Aes;
import haxe.crypto.Hmac;
import haxe.Exception;
import haxe.crypto.random.SecureRandom;

class HaxeAesHelper {
    #if target.threaded
    private static var lock:hx.concurrent.lock.RLock = new hx.concurrent.lock.RLock();
    #end

    private static function generateIV():Bytes {
        return SecureRandom.bytes(16);
    }

    private static function newAes(key:Bytes, iv:Bytes):Aes {
        var aes = new Aes();
        aes.init(key, iv);
        return aes;
    }

    public static function encrypt(bytes:Bytes):{iv: String, data: String, mac: String} {
        var key = Base64.decode(Environment.get("APP_KEY"));

        var iv = generateIV();

        var encryptedData = aesEncrypt(key, iv, bytes);
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

        return aesDecrypt(key, iv, data).toString();
    }

    private static function aesEncrypt(key:Bytes, iv:Bytes, bytes:Bytes):Bytes {
        #if target.threaded
        lock.acquire();
        try {
            var result = newAes(key, iv).encrypt(Mode.CBC, bytes, Padding.PKCS7);
            lock.release();
            return result;
        } catch (e:Dynamic) {
            lock.release();
            throw e;
        }
        #else
        return newAes(key, iv).encrypt(Mode.CBC, bytes, Padding.PKCS7);
        #end
    }

    private static function aesDecrypt(key:Bytes, iv:Bytes, data:Bytes):Bytes {
        #if target.threaded
        lock.acquire();
        try {
            var result = newAes(key, iv).decrypt(Mode.CBC, data, Padding.PKCS7);
            lock.release();
            return result;
        } catch (e:Dynamic) {
            lock.release();
            throw e;
        }
        #else
        return newAes(key, iv).decrypt(Mode.CBC, data, Padding.PKCS7);
        #end
    }
}
