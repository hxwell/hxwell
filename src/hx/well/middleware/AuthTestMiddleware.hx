package hx.well.middleware;
import hx.well.http.RequestStatic.auth;
import hx.well.model.User;

class AuthTestMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle():Void {
        var user:User = auth().user();
        if(user == null)
        {
            abort(401);
        }
    }
}