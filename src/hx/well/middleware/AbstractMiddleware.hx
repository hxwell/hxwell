package hx.well.middleware;
import hx.well.http.Request;
import hx.well.exception.AbortException;
import hx.well.http.RequestStatic;
import hx.well.model.User;
import sys.net.Socket;
import hx.well.http.Response;
abstract class AbstractMiddleware {
    public function new() {
    }

    public abstract function handle(request:Request, next:Request->Null<Response>):Null<Response>;

    public function abort(code:Int, ?status:String):Void
    {
        throw new AbortException(code, status);
    }

    public function dispose():Void
    {

    }
}
