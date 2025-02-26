package hx.well.boot;
import hx.well.server.AbstractServer;

@:keepSub
@:keep
abstract class BaseBoot {
    public function new() {

    }

    public abstract function boot():Void;

    public abstract function servers():Array<AbstractServer>;
}