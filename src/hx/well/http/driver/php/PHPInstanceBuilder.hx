package hx.well.http.driver.php;
import hx.well.server.instance.IInstance;

class PHPInstanceBuilder extends AbstractInstanceBuilder<PHPInstanceBuilder, AbstractDriverConfig> {
    private function new() {
        super(null);
    }

    public function build():IInstance {
        return new PHPInstance(config);
    }
}