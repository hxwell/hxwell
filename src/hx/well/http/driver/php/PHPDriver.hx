package hx.well.http.driver.php;

import hx.well.http.driver.AbstractHttpDriver;
import hx.well.http.driver.socket.SocketDriverConfig;
import haxe.Exception;

class PHPDriver extends AbstractHttpDriver<SocketDriverConfig> {

    public function new(config:SocketDriverConfig) {
        super(config);
    }

    public function start():Void {
        var context:PHPDriverContext = null;
        try {
            context = new PHPDriverContext();
            HttpHandler.process(context);
        } catch (e:Exception) {
            throw e;
        }
    }

    public function stop():Void {

    }
}