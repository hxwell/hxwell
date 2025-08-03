package hx.well.http.driver.php;

import hx.well.http.driver.AbstractHttpDriver;
import haxe.Exception;

class PHPDriver extends AbstractHttpDriver<AbstractDriverConfig> {

    public function new(config:AbstractDriverConfig) {
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