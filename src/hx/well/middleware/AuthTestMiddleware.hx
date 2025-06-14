package hx.well.middleware;
import hx.well.http.RequestStatic.auth;
import hx.well.model.User;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.Response;

class AuthTestMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        var user:User = auth().user();
        if(user == null)
        {
            abort(401);
        }
        return next(request);
    }
}