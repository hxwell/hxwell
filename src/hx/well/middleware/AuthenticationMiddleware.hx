package hx.well.middleware;

import hx.well.http.Request;
import hx.well.model.BaseModel;
import hx.well.session.SessionEnum;
import hx.well.http.RequestStatic.request;

class AuthenticationMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle():Void {
        var session = request().session;
        #if debug
        trace(session);
        #end
        if(session != null)
        {
            var authClassName:String = session.get(SessionEnum.AUTH_CLASS);
            if(authClassName != null) {
                var authID:Dynamic = session.get(SessionEnum.AUTH_ID);
                var user:Null<BaseModel<Any>> = Type.createInstance(Type.resolveClass(authClassName), []).find(authID);
                request().attributes.set("auth", user);
            }
        }
    }
}