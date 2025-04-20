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

class SessionMiddleware extends AbstractMiddleware {
    public function handle():Void {

        var sessionKey:Null<String> = request().cookie("sessionKey");

        var currentSession:ISession = new Session();
        currentSession.data = Cache.store(FileSystemSessionCacheStore).get('session.${sessionKey}', new Map());

        if(sessionKey == null)
        {
            currentSession.sessionKey = generateSessionKey();
            ResponseStatic.cookie("sessionKey", currentSession.sessionKey);
        }else{
            currentSession.sessionKey = sessionKey;
        }

        request().session = currentSession;
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