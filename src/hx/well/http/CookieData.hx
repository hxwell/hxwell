package hx.well.http;
import hx.well.facades.Crypt;

// Set-Cookie: sessionId=abc123; Secure; HttpOnly; SameSite=Strict; Path=/; Domain=example.com; Max-Age=3600
class CookieData {
    // Read Only
    public var key(default, null):String;
    public var value:String;
    public var secure:Bool = true;
    public var httpOnly:Bool = true;
    public var sameSite:Null<String> = "Lax"; // "Strict", "Lax", or null
    public var path:Null<String> = "/"; // Default is "/", can be set to a specific path
    public var domain:Null<String> = null; // Default is the host of the request, can be set to a specific domain
    public var maxAge:Null<Int> = null; // Max-Age in seconds, null means session cookie
    public var encrypt(default, null):Bool;


    public function new(key:String, value:String, encrypt:Bool = false) {
        this.key = key;
        this.encrypt = encrypt;
        this.value = encrypt ? Crypt.encrypt({key: key, value: value, createdAt: Math.floor(Date.now().getTime() / 1000), maxAge: maxAge, type: "cookie"}, true) : value;
        validate();
    }

    public function validate():Void {
        if(!HttpSyntax.isToken(key) || value == null)
            throw new haxe.Exception("Invalid cookie name or value");
        for(i in 0...value.length) {
            var code = value.charCodeAt(i);
            if(code < 0x21 || code > 0x7e || code == 0x22 || code == 0x2c || code == 0x3b || code == 0x5c)
                throw new haxe.Exception("Invalid cookie value; encode values before setting cookies");
        }
        validateAttribute(path);
        validateAttribute(domain);
        if(sameSite != null && !["lax", "strict", "none"].contains(HttpSyntax.lowerAscii(sameSite)))
            throw new haxe.Exception("Invalid cookie SameSite attribute");
    }

    public static function validateAttribute(value:String):Void {
        if(value == null) return;
        if(!HttpSyntax.isFieldValue(value) || value.indexOf("\t") >= 0 || value.indexOf(";") >= 0)
            throw new haxe.Exception("Invalid cookie attribute");
    }

    public function toString():String {
        validate();
        var cookieString = key + "=" + value;
        if (secure) cookieString += "; Secure";
        if (httpOnly) cookieString += "; HttpOnly";
        if (sameSite != null) cookieString += "; SameSite=" + sameSite;
        if (path != null) cookieString += "; Path=" + path;
        if (domain != null) cookieString += "; Domain=" + domain;
        if (maxAge != null) cookieString += "; Max-Age=" + maxAge;

        return cookieString;
    }

    public static function create(key:String, value:String, data:{encrypt:Bool, secure:Bool, httpOnly:Bool, sameSite:Null<String>, path:Null<String>, domain:Null<String>, maxAge:Null<Int>}):CookieData {
        var cookieData = new CookieData(key, value, data.encrypt ?? false);
        cookieData.secure = data.secure;
        cookieData.httpOnly = data.httpOnly;
        if(data.sameSite != null) cookieData.sameSite = data.sameSite;
        if(data.path != null) cookieData.path = data.path;
        if(data.domain != null) cookieData.domain = data.domain;
        if(data.maxAge != null) cookieData.maxAge = data.maxAge;
        return cookieData;
    }
}
