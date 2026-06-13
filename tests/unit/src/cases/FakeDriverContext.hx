package cases;

import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.driver.IDriverContext;
import hx.well.websocket.AbstractWebSocketHandler;

class FakeDriverContext implements IDriverContext {
    public var preparedRequest:Request;
    public var failBuild:Bool = false;
    public var written:Array<Response> = [];
    public var closed:Bool = false;

    @:isVar public var input(get, null):Input;
    function get_input():Input {
        return input;
    }

    @:isVar public var output(get, null):Output;
    function get_output():Output {
        return output;
    }

    public function new(?request:Request) {
        preparedRequest = request;
        input = new BytesInput(Bytes.alloc(0));
        output = new BytesOutput();
    }

    function buildRequest():Request {
        if (failBuild)
            throw new Exception("broken request");

        preparedRequest.context = this;
        return preparedRequest;
    }

    function parseBody():Void {}

    public function writeResponse(response:Response):Void {
        written.push(response);
    }

    public function beginWrite():Void {}

    public function writeInput(i:Input, ?bufsize:Int):Void {}

    public function writeString(s:String, ?encoding:haxe.io.Encoding):Void {}

    public function writeFullBytes(bytes:Bytes, pos:Int = 0, len:Int = -1):Void {}

    public function writeByte(c:Int):Void {}

    public function flush():Void {}

    public function close():Void {
        closed = true;
    }

    public function upgradeToWebSocket(request:Request, handler:AbstractWebSocketHandler):Void {}
}
