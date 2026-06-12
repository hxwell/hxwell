package hx.well.http.driver.php;

#if php
import hx.well.server.instance.IInstance;

class PHPInstanceBuilder extends AbstractInstanceBuilder<PHPInstanceBuilder, PHPDriverConfig> {
    private function new() {
        super(new PHPDriverConfig());
    }

    public function build():IInstance {
        return new PHPInstance(config);
    }
}
#end
