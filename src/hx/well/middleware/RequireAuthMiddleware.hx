package hx.well.middleware;
import haxe.ds.StringMap;
import hx.well.facades.Config;
import hx.well.http.Response;
import hx.well.http.Request;
import hx.well.auth.IAuthenticatable;
import hx.well.type.AttributeType;
import hx.well.http.RequestStatic.auth;
import hx.well.http.ResponseBuilder;
@:generic class RequireAuthMiddleware<@:const GUARD:String> extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var guards:StringMap<Class<IAuthenticatable>> = Config.get("session.guards");
        var guard:String = GUARD;
        if(!guards.exists(guard))
            throw guard + " guard not found!";

        request.setAttribute(AttributeType.DefaultGuard, guard);

        if(!auth().check())
            return ResponseBuilder.asRedirectRoute("login");

        return next(request);
    }
}