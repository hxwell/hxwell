package hx.well.http.driver.undertow;

#if java
import hx.well.http.driver.undertow.UndertowExtern.Option;
import hx.well.server.instance.IInstance;

class UndertowInstanceBuilder extends AbstractInstanceBuilder<UndertowInstanceBuilder, UndertowDriverConfig> {
    private function new() {
        super(new UndertowDriverConfig());
    }

    public function setServerOption<T>(option:Option<T>, value:T):UndertowInstanceBuilder {
        config.setServerOption(option, value);
        return this;
    }

    public function setSocketOption<T>(option:Option<T>, value:T):UndertowInstanceBuilder {
        config.setSocketOption(option, value);
        return this;
    }

    public function setWorkerOption<T>(option:Option<T>, value:T):UndertowInstanceBuilder {
        config.setWorkerOption(option, value);
        return this;
    }

    public function build():IInstance {
        return new UndertowInstance(config);
    }
}
#end