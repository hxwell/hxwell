package hx.well.middleware;
import hx.well.http.Request;
import hx.well.database.Connection;
import hx.well.http.Response;
import hx.well.http.Response;
class DatabaseMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        return next(request);
    }

    public override function dispose():Void
    {
        Connection.free();
        super.dispose();
    }
}