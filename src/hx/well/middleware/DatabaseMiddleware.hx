package hx.well.middleware;
import hx.well.http.Request;
import hx.well.database.Connection;
class DatabaseMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle():Void {

    }

    public override function dispose():Void
    {
        Connection.free();
        super.dispose();
    }
}