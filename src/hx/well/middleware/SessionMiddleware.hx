package hx.well.middleware;
import hx.well.http.Request;
import hx.well.session.ISession;
import hx.well.session.Session;
import uuid.Uuid;
import hx.well.facades.Cache;
import hx.well.model.User;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseStatic;
import hx.well.http.RequestStatic.request;
import hx.well.http.Response;
import hx.well.http.Response;
import hx.well.facades.Crypt;
import hx.well.facades.Environment;
import hx.well.facades.Config;
import haxe.CallStack;

class SessionMiddleware extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {

        var sessionCookieKey:String = '${Environment.get("APP_NAME")}_session';
        var encryptedSessionData:Null<String> = request.cookie(sessionCookieKey);
        trace(encryptedSessionData);
        var sessionKey:String = null;
        try {
            if(encryptedSessionData != null) {
                var sessionData:{key:String, value:String, createdAt:Float, type:String} = Crypt.decrypt(encryptedSessionData);
                var sessionLifeTimeSeconds:Int = Config.get("session.lifetime") * 60;
                trace(sessionData.type, sessionData.key, sessionData.value);
                if(sessionData.key == sessionCookieKey && sessionData.type == "cookie" && sessionData.createdAt + sessionLifeTimeSeconds > Math.floor(Date.now().getTime() / 1000))
                {
                    sessionKey = sessionData.value;
                }
            }
        } catch (e) {
            sessionKey = null;
        }

        var currentSession:ISession = new Session();
        currentSession.data = Cache.store(FileSystemSessionCacheStore).get('session.${sessionKey}', new Map());

        if(sessionKey == null)
        {
            currentSession.sessionKey = generateSessionKey();
        }else{
            currentSession.sessionKey = sessionKey;
        }

        ResponseStatic.cookie(sessionCookieKey, currentSession.sessionKey, true);
        request.session = currentSession;
        return next(request);
    }

    public function generateSessionKey():String
    {
        return Uuid.nanoId(32);
    }

    public override function dispose():Void
    {
        // Flush
        if(request().session != null)
            request().session.save();
    }
}