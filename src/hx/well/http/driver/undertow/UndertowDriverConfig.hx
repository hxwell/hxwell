package hx.well.http.driver.undertow;

#if java
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

    public var jksPath:Null<String>;
    public function setJksPath(path:String):Void {
        jksPath = path;
    }

    public var storePassword:Null<String> ;
    public function setStorePassword(password:String):Void {
        storePassword = password;
    }

    public var keyPassword:Null<String>;
    public function setKeyPassword(password:String):Void {
        keyPassword = password;
    }

    // TrustStore configuration for mutual TLS (mTLS)
    // If not set, Java's default trust manager will be used
    public var trustStorePath:Null<String>;

    public function setTrustStorePath(path:String):Void {
        trustStorePath = path;
    }

    public var trustStorePassword:Null<String>;

    public function setTrustStorePassword(password:String):Void {
        trustStorePassword = password;
    }
}
#end