package hx.well.handler;
import hx.well.http.Request;
import hx.well.http.AbstractResponse;
import sys.db.Connection;

abstract class AbstractHandler {
    public function new()
    {

    }

    public abstract function execute(request:Request):AbstractResponse;

    // Validate request data
    public function validate():Bool {
        return true;
    }

    public function connection(?key:String):Connection {
        return hx.well.database.Connection.get(key);
    }
}