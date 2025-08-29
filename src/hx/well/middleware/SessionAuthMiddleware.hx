package hx.well.middleware;

import hx.well.http.Request;
import hx.well.model.BaseModel;
import hx.well.session.SessionDataType;
import hx.well.http.RequestStatic.request;
import hx.well.http.Response;
import hx.well.type.AttributeType;
import hx.well.facades.Config;
import haxe.ds.StringMap;
import hx.well.auth.IAuthenticatable;

class SessionAuthMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var session = request.session;
        #if debug
        trace(session);
        #end
        if(session != null)
        {
            var guards:StringMap<Class<IAuthenticatable>> = Config.get("session.guards");
            for(guard in guards.keys())
            {
                var authID:Dynamic = session.getWithEnum(SessionDataType.AUTH_ID(guard));
                if(authID == null)
                    continue;

                var authenticatable:Class<BaseModel<IAuthenticatable>> = cast guards.get(guard);
                var user:IAuthenticatable = Type.createInstance(authenticatable, []).find(authID);
                request.setAttribute(AttributeType.Auth(guard), user);
            }
        }

        return next(request);
    }
}