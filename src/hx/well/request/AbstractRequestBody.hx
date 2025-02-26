package hx.well.request;
import haxe.io.Bytes;
abstract class AbstractRequestBody {
    public function new(bodyBytes:Bytes) {

    }

    public abstract function exists(key:String):Bool;
    public abstract function get(key:String):Null<Dynamic>;
    public abstract function keys():Array<String>;
}
