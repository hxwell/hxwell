package hx.well.http;
class CookieBuilder<T> {
    private var response:T;
    private var cookieData:CookieData;

    public function new(response:T, cookieData:CookieData) {
        this.response = response;
        this.cookieData = cookieData;
    }

    public function secure(secure:Bool):CookieBuilder<T> {
        cookieData.secure = secure;
        return this;
    }

    public function httpOnly(httpOnly:Bool):CookieBuilder<T> {
        cookieData.httpOnly = httpOnly;
        return this;
    }

    public function sameSite(sameSite:String):CookieBuilder<T> {
        if(sameSite != null && !["lax", "strict", "none"].contains(HttpSyntax.lowerAscii(sameSite)))
            throw new haxe.Exception("Invalid cookie SameSite attribute");
        cookieData.sameSite = sameSite;
        return this;
    }

    public function path(path:String):CookieBuilder<T> {
        CookieData.validateAttribute(path);
        cookieData.path = path;
        return this;
    }

    public function domain(domain:String):CookieBuilder<T> {
        CookieData.validateAttribute(domain);
        cookieData.domain = domain;
        return this;
    }

    public function maxAge(maxAge:Int):CookieBuilder<T> {
        cookieData.maxAge = maxAge;
        return this;
    }

    public function get():T {
        return response;
    }
}
