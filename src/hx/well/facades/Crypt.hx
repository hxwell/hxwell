package hx.well.facades;

import haxe.crypto.Aes;
import haxe.crypto.Base64;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.io.Bytes;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Exception;
import haxe.crypto.Hmac.HashMethod.SHA256;
import haxe.crypto.Hmac;

class Crypt {
    private static inline var TYPE_DYNAMIC = "dynamic";
    private static inline var TYPE_STRING = "string";
    private static inline var TYPE_SERIALIZED = "serialized";

    public static function encryptString(value: String): String {
        return encrypt(value);
    }

    public static function encrypt<T>(value: T, forceToDynamic:Bool = false): String {
        var aes = new Aes();

        // Allocate IV Bytes
        var iv = Bytes.alloc(16);

        // Generate IV
        // TODO: The IV (Initialization Vector) must be generated using a secure random number generator (PRNG).
        for(i in 0...iv.length)
            iv.set(i, Std.random(256));

        var key = Base64.decode(Environment.get("APP_KEY"));

        aes.init(key, iv);

        var processedValue: Dynamic;
        var dataType: String;

        if(forceToDynamic) {
            processedValue = value;
            dataType = TYPE_DYNAMIC;
        } else if (Std.isOfType(value, String)) {
            processedValue = value;
            dataType = TYPE_STRING;
        } else {
            processedValue = Serializer.run(value);
            dataType = TYPE_SERIALIZED;
        }

        var objectData = Json.stringify({
            value: processedValue,
            type: dataType
        });

        var bytesData = Bytes.ofString(objectData);
        // CBC not working?
        var encryptedData = aes.encrypt(#if true Mode.CTR #else Mode.CBC #end, bytesData, Padding.NoPadding);
        var encryptedDataString = Base64.encode(encryptedData);

        var ivHex = iv.toHex();

        var hmac = new Hmac(SHA256);

        var result = Json.stringify({
            iv: ivHex,
            data: encryptedDataString,
            mac: hmac.make(key, Bytes.ofString(ivHex + encryptedDataString)).toHex()
        });

        return Base64.encode(Bytes.ofString(result));
    }

    public static function decryptString(value: String): String {
        return decrypt(value);
    }

    public static function decrypt<T>(value: String): T {
        var aes = new Aes();

        var decoded = Base64.decode(value);
        var decodedStr = decoded.toString();

        var parsed: {iv: String, data: String, mac: String} = Json.parse(decodedStr);

        var iv = Bytes.ofHex(parsed.iv);
        var data = Base64.decode(parsed.data);
        var key = Base64.decode(Environment.get("APP_KEY"));

        // HMAC validation
        var hmac = new Hmac(SHA256);
        var expectedMac = hmac.make(key, Bytes.ofString(parsed.iv + parsed.data)).toHex();

        if (expectedMac != parsed.mac) {
            throw new Exception("HMAC validation failed - data may be corrupted or tampered with");
        }

        aes.init(key, iv);

        // CBC not working?
        var decryptedBytes = aes.decrypt(#if true Mode.CTR #else Mode.CBC #end, data, Padding.NoPadding);
        var decryptedStr = decryptedBytes.toString();
        var decryptedObj: {value: String, type: String} = Json.parse(decryptedStr);

        return switch (decryptedObj.type) {
            case TYPE_STRING:
                cast decryptedObj.value;
            case TYPE_DYNAMIC:
                // Required for java target
                var dynamicValue:T = cast decryptedObj.value;
                dynamicValue;
            case TYPE_SERIALIZED:
                Unserializer.run(decryptedObj.value);
            default:
                throw new Exception("Unknown data type");
        }
    }
}