package hx.well.internal;

#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import haxe.io.Bytes;
import haxe.crypto.Base64;
import haxe.Exception;
import hx.well.facades.Environment;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import java.security.SecureRandom;
import java.NativeArray;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.spec.IvParameterSpec;

class JavaAesHelper {
    private static function generateIV():Bytes {
        var iv = new NativeArray<Int8>(16);
        new SecureRandom().nextBytes(iv);
        return Bytes.ofData(cast iv);
    }

    public static function encrypt(bytes:Bytes):{iv: String, data: String, mac: String} {
        var key = Base64.decode(Environment.get("APP_KEY"));

        // Convert Haxe Bytes to Java byte array
        var keyBytes:NativeArray<Int8> = cast key.getData();
        var dataBytes:NativeArray<Int8> = cast bytes.getData();

        var iv = generateIV();

        try {
            // Create cipher instance for AES-GCM
            var cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            var secretKey = new SecretKeySpec(keyBytes, "AES");
            var ivSpec = new IvParameterSpec(cast iv.getData()); // 128-bit authentication tag

            cipher.init(Cipher.ENCRYPT_MODE, secretKey, ivSpec);
            var encryptedBytes = cipher.doFinal(dataBytes);

            // Convert IV to hex string
            var ivHex = iv.toHex();

            // Convert encrypted data to Haxe Bytes then Base64
            var encryptedHaxeBytes = Bytes.ofData(cast encryptedBytes);
            var encryptedDataString = Base64.encode(encryptedHaxeBytes);

            // Calculate HMAC using Java's Mac
            var hmacKey = new SecretKeySpec(keyBytes, "HmacSHA256");
            var mac = Mac.getInstance("HmacSHA256");
            mac.init(hmacKey);

            var hmacDataBytes = Bytes.ofString(ivHex + encryptedDataString);

            var hmacResult = Bytes.ofData(cast mac.doFinal(cast hmacDataBytes.getData()));
            var hmacHex = hmacResult.toHex();

            return {iv: ivHex, data: encryptedDataString, mac: hmacHex};

        } catch (e:Dynamic) {
            throw e;
            throw new Exception("Encryption failed: " + e);
        }
    }

    public static function decrypt(raw_iv: String, raw_data: String, raw_mac: String):String {
        var key = Base64.decode(Environment.get("APP_KEY"));

        // Convert Haxe Bytes to Java byte array
        var keyBytes = new NativeArray<Int8>(key.length);
        for (i in 0...key.length) {
            keyBytes[i] = key.get(i);
        }

        try {
            // Verify HMAC first
            var hmacKey = new SecretKeySpec(keyBytes, "HmacSHA256");
            var mac = Mac.getInstance("HmacSHA256");
            mac.init(hmacKey);

            var hmacData = raw_iv + raw_data;
            var hmacDataBytes = new NativeArray<Int8>(hmacData.length);
            for (i in 0...hmacData.length) {
                hmacDataBytes[i] = hmacData.charCodeAt(i);
            }

            var expectedMacBytes = Bytes.ofData(cast mac.doFinal(hmacDataBytes));
            var expectedMac = expectedMacBytes.toHex();

            if (expectedMac.toLowerCase() != raw_mac.toLowerCase()) {
                throw new Exception("HMAC validation failed - data may be corrupted or tampered");
            }

            // Convert hex IV to byte array
            var iv:NativeArray<Int8> = cast Bytes.ofHex(raw_iv).getData();

            // Decode base64 data
            var data = Base64.decode(raw_data);
            var dataBytes = new NativeArray<Int8>(data.length);
            for (i in 0...data.length) {
                dataBytes[i] = data.get(i);
            }

            // Decrypt using AES-GCM
            var cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            var secretKey = new SecretKeySpec(keyBytes, "AES");
            var ivSpec = new IvParameterSpec(iv);

            cipher.init(Cipher.DECRYPT_MODE, secretKey, ivSpec);
            var decryptedBytes = Bytes.ofData(cast cipher.doFinal(dataBytes));

            // Convert back to string
            var result = decryptedBytes.toString();

            return result;

        } catch (e:Dynamic) {
            throw e;
            throw new Exception("Decryption failed: " + e);
        }
    }
}