package hx.well.http.driver;
import hx.well.server.instance.IInstance;

abstract class AbstractInstanceBuilder<B:AbstractInstanceBuilder<B, T>, T:AbstractDriverConfig> {
    private var config:T;

    private function new(config:T) {
        this.config = config;
    }

    public function setSsl(value:Bool):B {
        config.ssl = value;
        return cast this;
    }

    public function setHost(value:String):B {
        config.host = value;
        return cast this;
    }

    public function setPort(value:Int):B {
        config.port = value;
        return cast this;
    }

    public function setPoolSize(value:Int):B {
        config.poolSize = value;
        return cast this;
    }

    public function setMaxConnections(value:Int):B {
        config.maxConnections = value;
        return cast this;
    }

    public abstract function build():IInstance;
}
