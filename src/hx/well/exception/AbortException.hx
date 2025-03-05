package hx.well.exception;
import haxe.Exception;
class AbortException extends Exception {
    public var statusCode(default, null):Int;
    public var statusMessage(default, null):String;

    public function new(statusCode:Int, ?statusMessage:String) {
        super("abort");

        this.statusCode = statusCode;
        this.statusMessage = statusMessage;
    }
}
