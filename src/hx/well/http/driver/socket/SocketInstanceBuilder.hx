package hx.well.http.driver.socket;
#if (!php && !js)
import hx.well.server.instance.IInstance;

class SocketInstanceBuilder extends AbstractInstanceBuilder<SocketInstanceBuilder, SocketDriverConfig> {
    private function new() {
        super(new SocketDriverConfig());
    }

    public function build():IInstance {
        return new SocketInstance(config);
    }
}
#end