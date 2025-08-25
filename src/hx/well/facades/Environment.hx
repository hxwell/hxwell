package hx.well.facades;
import sys.io.File;
import sys.FileSystem;
import haxe.ds.StringMap;
import hx.well.facades.Environment;
import hx.concurrent.collection.SynchronizedMap;
using StringTools;
class Environment {
    private static var data:SynchronizedMap<String, String> = SynchronizedMap.newStringMap();

    public static function clear():Void {
        data.clear();
    }

    public static function load(path:String = ".env"):Void {
        var data:StringMap<String> = new StringMap();

        if (!FileSystem.exists(path)) {
            throw ".env file not found";
            return;
        }

        var content = File.getContent(path);
        var lines = content.split('\n');

        for (line in lines) {
            var trimmed = StringTools.trim(line);
            if (trimmed == "" || trimmed.charAt(0) == "#") continue;

            var eqPos = trimmed.indexOf("=");
            if (eqPos == -1) continue;

            var key = StringTools.trim(trimmed.substring(0, eqPos));
            var valuePart = StringTools.trim(trimmed.substr(eqPos + 1));

            var quoteChar = null;
            if (valuePart.startsWith('"') || valuePart.startsWith("'")) {
                quoteChar = valuePart.charAt(0);
                valuePart = valuePart.substr(1);
            }

            var endQuotePos = -1;
            if (quoteChar != null) {
                endQuotePos = valuePart.lastIndexOf(quoteChar);
            }

            var value = if (quoteChar != null && endQuotePos != -1) {
                valuePart.substring(0, endQuotePos);
            } else {
                // If no quotes, take before #
                var hashIndex = valuePart.indexOf("#");
                if (hashIndex != -1) valuePart = valuePart.substring(0, hashIndex);
                StringTools.trim(valuePart);
            };

            // Environment variable expansion
            value = expandEnvVars(value, data);

            data.set(key, value);
        }

        Environment.data = SynchronizedMap.from(data);

        checkEnv();
    }

    public static function get(key:String, ?defaultValue:String):String {
        return data.exists(key) ? data.get(key) : defaultValue;
    }

    public static function set(key:String, value:String):Void {
        data.set(key, value);
    }

    public static function exists(key:String):Bool {
        return data.exists(key);
    }

    public static function expandEnvVars(value:String, ?data:StringMap<String>):String {
        var get:String->String = data == null ? Environment.data.get : data.get;

        var regex = ~/\$\{([a-zA-Z0-9_-]+)\}/;
        while (regex.match(value)) {
            var envVar = regex.matched(1);
            trace(envVar);
            value = regex.matchedLeft() + get(envVar) + regex.matchedRight();
        }

        var regexDollar = ~/\$([a-zA-Z0-9_-]+)/;
        while (regexDollar.match(value)) {
            var envVar = regexDollar.matched(1);
            trace(envVar);
            value = regexDollar.matchedLeft() + get(envVar) + regexDollar.matchedRight();
        }

        return value;
    }

    private static function checkEnv():Void {
        var appKey = get("APP_KEY", "");

        if(appKey == "") {
            throw "APP_KEY is not set in .env file, generate it using 'haxelib run hxwell generate:key'";
        }
    }
}