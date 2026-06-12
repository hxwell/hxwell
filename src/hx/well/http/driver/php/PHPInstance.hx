package hx.well.http.driver.php;

#if php
import hx.well.server.instance.AbstractInstance;

class PHPInstance extends AbstractInstance<PHPDriver, PHPDriverConfig> {
    public static function builder():PHPInstanceBuilder {
        return @:privateAccess new PHPInstanceBuilder();
    }

    public function driver():PHPDriver {
        return new PHPDriver(config);
    }
}
#end
