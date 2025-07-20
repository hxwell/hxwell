package hx.well.http.driver.undertow;
import hx.well.http.driver.undertow.UndertowExtern.Option;

class UndertowDriverConfig extends AbstractDriverConfig {
    public var serverOption:Map<Option<Any>, Any> = [];
    public function setServerOption<T>(option:Option<T>, value:T):Void {
        serverOption.set(option, value);
    }

    public var socketOption:Map<Option<Any>, Any> = [];
    public function setSocketOption<T>(option:Option<T>, value:T):Void {
        socketOption.set(option, value);
    }

    public var workerOption:Map<Option<Any>, Any> = [];
    public function setWorkerOption<T>(option:Option<T>, value:T):Void {
        workerOption.set(option, value);
    }
}