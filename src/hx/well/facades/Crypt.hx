package hx.well.facades;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Exception;
import hx.well.internal.CryptHelper;

class Crypt {
    private static inline var TYPE_DYNAMIC = "dynamic";
    private static inline var TYPE_STRING = "string";
    private static inline var TYPE_SERIALIZED = "serialized";

    public static function encryptString(value: String): String {
        return encrypt(value);
    }

    public static function encrypt<T>(value: T, forceToDynamic:Bool = false): String {
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
        var result = Json.stringify(CryptHelper.encrypt(bytesData));
        return Base64.encode(Bytes.ofString(result));
    }

    public static function decryptString(value: String): String {
        return decrypt(value);
    }

    public static function decrypt<T>(value: String): T {
        var decoded = Base64.decode(value);
        var decodedStr = decoded.toString();

        var parsed: {iv: String, data: String, mac: String} = Json.parse(decodedStr);

        var decryptedStr = CryptHelper.decrypt(parsed.iv, parsed.data, parsed.mac);
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