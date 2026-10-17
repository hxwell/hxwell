package hx.well.middleware;

import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.http.CookieData;
import hx.well.session.ISession;
import hx.well.facades.Config;
import hx.well.internal.SecureToken;

class CsrfMiddleware extends AbstractMiddleware {
    public static inline var TOKEN_KEY:String = "_token";
    public static inline var COOKIE_KEY:String = "XSRF-TOKEN";

    private static var readMethods:Array<String> = ["GET", "HEAD", "OPTIONS", "TRACE"];

    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var session:ISession = request.session;
        if(session == null)
            return next(request);

        var token:String = session.get(TOKEN_KEY);
        if(token == null) {
            token = generateToken();
            session.put(TOKEN_KEY, token);
        }

        if(!isReadMethod(request.method) && !tokenMatches(request, token))
            abort(419);

        issueXsrfCookie(token);

        return next(request);
    }

    public static function token():Null<String> {
        var session:ISession = hx.well.http.RequestStatic.request()?.session;
        return session?.get(TOKEN_KEY);
    }

    private function issueXsrfCookie(token:String):Void {
        if(ResponseStatic.get() == null)
            return;

        var cookieData:CookieData = new CookieData(COOKIE_KEY, token);
        cookieData.httpOnly = false;
        cookieData.maxAge = Config.get("session.lifetime") * 60;
        ResponseStatic.cookieFromData(cookieData.key, cookieData);
    }

    public function generateToken():String {
        return SecureToken.generate(40);
    }

    private function isReadMethod(method:String):Bool {
        return method != null && readMethods.contains(method.toUpperCase());
    }

    private function tokenMatches(request:Request, token:String):Bool {
        var provided:String = request.header("X-CSRF-TOKEN");

        if(provided == null)
            provided = request.header("X-XSRF-TOKEN");

        if(provided == null) {
            var input:Dynamic = request.input(TOKEN_KEY);
            if(input != null)
                provided = Std.string(input);
        }

        return secureEquals(token, provided);
    }

    private function secureEquals(expected:String, provided:String):Bool {
        if(expected == null || provided == null || expected.length != provided.length)
            return false;

        var diff:Int = 0;
        for(i in 0...expected.length)
            diff |= expected.charCodeAt(i) ^ provided.charCodeAt(i);

        return diff == 0;
    }
}
