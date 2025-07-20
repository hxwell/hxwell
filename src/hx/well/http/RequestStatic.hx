package hx.well.http;
import haxe.ThreadLocal;
import hx.well.facades.Auth;
import hx.well.http.driver.IDriverContext;

@:allow(hx.well.http.HttpHandler)
@:allow(hx.well.http.driver.AbstractHttpDriver)
class RequestStatic {
    private static var threadLocal:ThreadLocal<Request> = new ThreadLocal();

    public static function request():Request {
        return threadLocal.get();
    }

    public static function reset():Void {
        set(null);
    }

    public static function set(request:Request):Void {
        return threadLocal.set(request);
    }

    public static function auth():Auth {
        return new Auth(request());
    }

    public static function cookie(key:String, ?defaultValue:String):String {
        return request().cookie(key, defaultValue);
    }

    public static function header(key:String, ?defaultValue:String):String {
        return request().header(key, defaultValue);
    }

    public static function context():IDriverContext {
        return request().context;
    }
}