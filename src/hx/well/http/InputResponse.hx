package hx.well.http;
import haxe.io.Input;
import hx.well.http.Response;
import haxe.Int64;
class InputResponse extends Response {
    public var input:Input;

    public function new(input:Input, size:Null<Int64>, statusCode:Null<Int> = null) {
        super(statusCode);
        this.input = input;
        this.contentLength = size;
    }

    override public function toInput():Input {
        return input;
    }

    public override function dispose():Void
    {
        input.close();
    }
}
