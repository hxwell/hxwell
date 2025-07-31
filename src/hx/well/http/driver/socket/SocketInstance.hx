package hx.well.http.driver.socket;
#if (!php && !js)
import hx.well.server.instance.AbstractInstance;

class SocketInstance extends AbstractInstance<SocketDriver, SocketDriverConfig> {
    public static function builder():SocketInstanceBuilder {
        return @:privateAccess new SocketInstanceBuilder();
    }

    public function driver():SocketDriver {
        return new SocketDriver(config);
    }
}
#end