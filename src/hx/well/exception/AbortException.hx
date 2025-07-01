package hx.well.exception;
import haxe.Exception;
class AbortException extends Exception {
    public var statusCode(default, null):Int;
    public var statusMessage(default, null):String;
    public var parent(default, null):Exception;

    private function new(statusCode:Int, ?statusMessage:String, parent:Exception = null) {
        super("AbortException: " + statusCode + (statusMessage != null ? " - " + statusMessage : ""));

        this.statusCode = statusCode;
        this.statusMessage = statusMessage;
        this.parent = parent;
    }
}
