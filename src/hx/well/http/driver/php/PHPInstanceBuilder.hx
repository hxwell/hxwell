package hx.well.http.driver.php;
import hx.well.server.instance.IInstance;
import hx.well.http.driver.socket.SocketDriverConfig;

class PHPInstanceBuilder extends AbstractInstanceBuilder<PHPInstanceBuilder, SocketDriverConfig> {
    private function new() {
        super(new SocketDriverConfig());
    }

    public function build():IInstance {
        return new PHPInstance(config);
    }
}