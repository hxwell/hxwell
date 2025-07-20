package hx.well.http.driver.php;
import hx.well.server.instance.AbstractInstance;
import hx.well.http.driver.socket.SocketDriverConfig;

class PHPInstance extends AbstractInstance<PHPDriver, SocketDriverConfig> {
    public static function builder():PHPInstanceBuilder {
        return @:privateAccess new PHPInstanceBuilder();
    }

    public function driver():PHPDriver {
        return new PHPDriver(config);
    }
}