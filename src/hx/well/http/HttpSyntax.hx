package hx.well.http;

import haxe.Exception;

/** Shared validation for HTTP metadata, before any bytes reach a driver. */
class HttpSyntax {
    public static function lowerAscii(value:String):String {
        var result = new StringBuf();
        for(i in 0...value.length) {
            var code = value.charCodeAt(i);
            result.addChar(code >= 65 && code <= 90 ? code + 32 : code);
        }
        return result.toString();
    }

    public static function isToken(value:String):Bool {
        if(value == null || value.length == 0) return false;
        for(i in 0...value.length) {
            var code = value.charCodeAt(i);
            if((code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122)) continue;
            if("!#$%&'*+-.^_`|~".indexOf(value.charAt(i)) >= 0) continue;
            return false;
        }
        return true;
    }

    public static function isFieldValue(value:String):Bool {
        if(value == null) return false;
        for(i in 0...value.length) {
            var code = value.charCodeAt(i);
            if((code < 32 && code != 9) || code == 127) return false;
        }
        return true;
    }

    public static function header(name:String, value:String):Void {
        if(!isToken(name) || !isFieldValue(value))
            throw new Exception("Invalid HTTP header");
    }

    public static function reason(value:String):Void {
        if(value != null && !isFieldValue(value))
            throw new Exception("Invalid HTTP status message");
    }

    public static function trimOWS(value:String):String {
        var start = 0;
        var end = value.length;
        while(start < end && (value.charCodeAt(start) == 32 || value.charCodeAt(start) == 9)) start++;
        while(end > start && (value.charCodeAt(end - 1) == 32 || value.charCodeAt(end - 1) == 9)) end--;
        return value.substring(start, end);
    }
}
