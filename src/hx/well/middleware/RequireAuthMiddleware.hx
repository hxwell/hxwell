package hx.well.middleware;
import haxe.ds.StringMap;
import hx.well.facades.Config;
import hx.well.http.Response;
import hx.well.http.Request;
import hx.well.auth.IAuthenticatable;
import hx.well.type.AttributeType;
import hx.well.http.RequestStatic.auth;
import hx.well.http.ResponseBuilder;
// Keep the const-specialized class independent of runtime Config/Route typing.
// Otherwise config discovery can re-enter an unspecialized GUARD on Haxe 4.
@:generic class RequireAuthMiddleware<@:const GUARD:String> extends AuthGuardMiddleware {
    public function new() {
        super(GUARD);
    }
}

private class AuthGuardMiddleware extends AbstractMiddleware {
    private var guard:String;

    public function new(guard:String) {
        super();
        this.guard = guard;
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var guards:StringMap<Class<IAuthenticatable>> = Config.get("session.guards");
        if(!guards.exists(guard))
            throw guard + " guard not found!";

        request.setAttribute(AttributeType.DefaultGuard, guard);

        if(!auth().check())
            return redirectTo(request);

        return next(request);
    }

    private function redirectTo(request:Request):Null<Response> {
        return ResponseBuilder.asRedirectRoute("login");
    }
}
