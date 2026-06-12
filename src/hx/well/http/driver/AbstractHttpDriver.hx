package hx.well.http.driver;

abstract class AbstractHttpDriver<T:AbstractDriverConfig> {
    public var config:T;

    public function new(config:T) {
        this.config = config;
    }

    public abstract function start():Void;
    public abstract function stop():Void;
}