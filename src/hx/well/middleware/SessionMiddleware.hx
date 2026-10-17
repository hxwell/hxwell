package hx.well.middleware;
import hx.well.session.ISession;
import hx.well.http.Request;
import hx.well.session.ISession;
import hx.well.session.Session;
import hx.well.internal.SecureToken;
import hx.well.facades.Cache;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.http.ResponseStatic;
import hx.well.http.RequestStatic.request;
import hx.well.http.Response;
import hx.well.facades.Crypt;
import hx.well.facades.Environment;
import hx.well.facades.Config;
import haxe.CallStack;
import hx.well.http.CookieData;

class SessionMiddleware extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var cookieKey:String = sessionCookieKey();
        var encryptedSessionData:Null<String> = request.cookie(cookieKey);
        var sessionKey:String = null;
        var sessionCreatedAt:Float = 0;
        try {
            if(encryptedSessionData != null) {
                var sessionData:{
                    key:String,
                    value:String,
                    createdAt:Float,
                    type:String
                } = Crypt.decrypt(encryptedSessionData);
                var sessionLifeTimeSeconds:Int = Config.get("session.lifetime") * 60;
                if(sessionData.key == cookieKey
                && sessionData.type == "cookie"
                && sessionData.createdAt + sessionLifeTimeSeconds > Math.floor(Date.now().getTime() / 1000)) {
                    sessionKey = sessionData.value;
                    sessionCreatedAt = sessionData.createdAt;
                }
            }
        } catch (e) {
            trace(e, CallStack.toString(e.stack));
            sessionKey = null;
        }

        var currentSession:ISession = new Session();
        var storedData:Map<String, Dynamic> = sessionKey == null ? null : Cache.store(FileSystemSessionCacheStore).get('session.${sessionKey}');
        if(storedData == null)
            sessionKey = null;
        currentSession.data = storedData ?? new Map();

        if(sessionKey == null)
        {
            currentSession.sessionKey = generateSessionKey();
        }else{
            currentSession.sessionKey = sessionKey;
        }

        var now:Float = Math.floor(Date.now().getTime() / 1000);
        var needsRefresh:Bool = sessionKey == null || (now - sessionCreatedAt) >= 60;

        if(needsRefresh) {
            issueSessionCookie(currentSession.sessionKey);
        }

        currentSession.needsRefresh = needsRefresh;
        request.session = currentSession;
        return next(request);
    }

    public function cookieData(key:String, value:String, encrypt:Bool):CookieData
    {
        return new CookieData(key, value, encrypt);
    }

    public static function sessionCookieKey():String
    {
        return '${Environment.get("APP_NAME")}_session';
    }

    public static function issueSessionCookie(sessionKey:String):Void
    {
        if(ResponseStatic.get() == null)
            return;

        var cookieData:CookieData = new CookieData(sessionCookieKey(), sessionKey, true);
        cookieData.maxAge = Config.get("session.lifetime") * 60;
        ResponseStatic.cookieFromData(cookieData.key, cookieData);
    }

    public static function generateSessionKey():String
    {
        return SecureToken.generate(32);
    }

    public override function dispose():Void
    {
        var session:ISession = request().session;
        if (session != null) {
            if (!session.save() && session.needsRefresh)
                session.touch();
        }
    }
}
