package hx.well.http.driver.php;

#if php
import hx.well.http.driver.AbstractHttpDriver;

class PHPDriver extends AbstractHttpDriver<PHPDriverConfig> {

    public function new(config:PHPDriverConfig) {
        super(config);
    }

    public function start():Void {
        HttpHandler.process(new PHPDriverContext());
    }

    public function stop():Void {

    }
}
#end