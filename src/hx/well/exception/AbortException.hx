package hx.well.exception;
import haxe.Exception;
class AbortException extends Exception {
    public var code(default, null):Int;
    public var status(default, null):String;

    public function new(code:Int, ?status:String) {
        super("abort");

        this.code = code;
        this.status = status;
    }
}
