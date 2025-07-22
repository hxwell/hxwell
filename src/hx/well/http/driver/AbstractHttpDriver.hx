package hx.well.http.driver;

abstract class AbstractHttpDriver<T:AbstractDriverConfig> {
    public var config:T;
    public var startCallback:Void->Void = () -> {};

    public function new(config:T) {
        this.config = config;
    }

    public abstract function start():Void;
    public abstract function stop():Void;

    public function onStart(callback:Void->Void):Void {
        this.startCallback = callback;
    }
}