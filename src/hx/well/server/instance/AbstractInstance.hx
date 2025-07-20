package hx.well.server.instance;
import hx.well.http.driver.AbstractHttpDriver;
import hx.well.http.driver.AbstractDriverConfig;

abstract class AbstractInstance<D:AbstractHttpDriver<C>, C:AbstractDriverConfig> implements IInstance {
    private var config:C;

    public function new(config:C) {
        this.config = config;
    }

    public abstract function driver():D;
}