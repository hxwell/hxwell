package hx.well.boot;
import hx.well.server.instance.IInstance;

@:keepSub
@:keep
abstract class BaseBoot {
    public function new() {

    }

    public abstract function boot():Void;

    public abstract function instances():Array<IInstance>;
}