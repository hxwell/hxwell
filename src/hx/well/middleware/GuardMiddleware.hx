package hx.well.middleware;

import haxe.ds.StringMap;
import hx.well.auth.IAuthenticatable;
import hx.well.facades.Config;
import hx.well.http.Request;
import hx.well.http.RequestStatic.request;
import hx.well.http.Response;
import hx.well.type.AttributeType;

@:generic class GuardMiddleware<@:const KEY:String> extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var guards:StringMap<Class<IAuthenticatable>> = Config.get("session.guards");
        var guard:String = KEY;
        if(!guards.exists(guard))
            throw guard + " guard not found!";

        request.setAttribute(AttributeType.DefaultGuard, guard);

        return next(request);
    }
}