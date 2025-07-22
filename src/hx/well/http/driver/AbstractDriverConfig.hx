package hx.well.http.driver;

abstract class AbstractDriverConfig {
    public function new() {}

    public var ssl:Bool = false;
    public var host:String = "127.0.0.1";
    public var port:Int = 1337;
    public var poolSize:Int = 10;
    public var maxConnections:Int = 100;
    public var onStart:Void->Void = () -> {};
}