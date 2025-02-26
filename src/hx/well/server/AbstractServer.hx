package hx.well.server;
import sys.net.Host;
import sys.net.Socket;
import hx.concurrent.executor.Executor;
import hx.well.middleware.AbstractMiddleware;
import hx.well.middleware.DatabaseMiddleware;
import hx.well.middleware.SessionMiddleware;
import hx.well.middleware.AuthTestMiddleware;
import hx.well.middleware.AuthenticationMiddleware;
abstract class AbstractServer {
    public function new() {

    }

    public abstract function host():Host;

    public abstract function port():Int;

    public function socket():Socket {
        return new Socket();
    }

    public function executor():Executor {
        return Executor.create(maxConnections() + 4);
    }

    public function maxConnections():Int {
        return 28;
    }

    public function middlewares():Array<Class<AbstractMiddleware>> {
        return [
            DatabaseMiddleware,
            SessionMiddleware,
            AuthenticationMiddleware,
            //AuthTestMiddleware
        ];
    }
}
