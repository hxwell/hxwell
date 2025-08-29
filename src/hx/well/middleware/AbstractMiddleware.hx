package hx.well.middleware;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
abstract class AbstractMiddleware {
    public function new() {
    }

    public abstract function handle(request:Request, next:Request->Null<Response>):Null<Response>;

    public inline function abort(code:Int, ?status:String):Void
    {
        ResponseStatic.abort(code, status);
    }

    public function dispose():Void
    {

    }
}
