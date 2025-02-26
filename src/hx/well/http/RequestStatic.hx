package hx.well.http;
import haxe.ThreadLocal;
import sys.net.Socket;
import hx.well.facades.AuthStatic;
import hx.well.facades.Auth;

@:allow(hx.well.WebServer)
class RequestStatic {
    private static var threadLocal:ThreadLocal<Request> = new ThreadLocal();

    public static function request():Request {
        return threadLocal.get();
    }

    private static function set(request:Request):Void {
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

    public static function socket():Socket {
        return request().socket;
    }
}