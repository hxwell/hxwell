package hx.well.http;

// Set-Cookie: sessionId=abc123; Secure; HttpOnly; SameSite=Strict; Path=/; Domain=example.com; Max-Age=3600
class CookieData {
    public var key:String;
    public var value:String;
    public var secure:Bool = true;
    public var httpOnly:Bool = true;
    public var sameSite:Null<String> = null; // "Strict", "Lax", or null
    public var path:Null<String> = null; // Default is "/", can be set to a specific path
    public var domain:Null<String> = null; // Default is the host of the request, can be set to a specific domain
    public var maxAge:Null<Int> = null; // Max-Age in seconds, null means session cookie


    public function new(key:String, value:String) {
        this.key = key;
        this.value = value;
    }

    public function toString():String {
        var cookieString = key + "=" + value;
        if (secure) cookieString += "; Secure";
        if (httpOnly) cookieString += "; HttpOnly";
        if (sameSite != null) cookieString += "; SameSite=" + sameSite;
        if (path != null) cookieString += "; Path=" + path;
        if (domain != null) cookieString += "; Domain=" + domain;
        if (maxAge != null) cookieString += "; Max-Age=" + maxAge;

        return cookieString;
    }

    public static function create(key:String, value:String, data:{secure:Bool, httpOnly:Bool, sameSite:Null<String>, path:Null<String>, domain:Null<String>, maxAge:Null<Int>}):CookieData {
        var cookieData = new CookieData(key, value);
        cookieData.secure = data.secure;
        cookieData.httpOnly = data.httpOnly;
        if(data.sameSite != null) cookieData.sameSite = data.sameSite;
        if(data.path != null) cookieData.path = data.path;
        if(data.domain != null) cookieData.domain = data.domain;
        if(data.maxAge != null) cookieData.maxAge = data.maxAge;
        return cookieData;
    }
}
