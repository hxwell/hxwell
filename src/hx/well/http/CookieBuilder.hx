package hx.well.http;
class CookieBuilder<T> {
    private var response:T;
    private var cookieData:CookieData;

    public function new(response:T, cookieData:CookieData) {
        this.response = response;
    }

    private function setSecure(secure:Bool):CookieBuilder<T> {
        cookieData.secure = secure;
        return this;
    }

    private function setHttpOnly(httpOnly:Bool):CookieBuilder<T> {
        cookieData.httpOnly = httpOnly;
        return this;
    }

    private function setSameSite(sameSite:String):CookieBuilder<T> {
        cookieData.sameSite = sameSite;
        return this;
    }

    private function setPath(path:String):CookieBuilder<T> {
        cookieData.path = path;
        return this;
    }

    private function setDomain(domain:String):CookieBuilder<T> {
        cookieData.domain = domain;
        return this;
    }

    private function setMaxAge(maxAge:Int):CookieBuilder<T> {
        cookieData.maxAge = maxAge;
        return this;
    }

    public function get():T {
        return response;
    }
}
