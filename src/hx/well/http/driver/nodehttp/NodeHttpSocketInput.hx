package hx.well.http.driver.nodehttp;

#if js
import haxe.io.Input;
import js.node.http.IncomingMessage;

// TODO: Optimize
class NodeHttpSocketInput extends Input {
    private var incomingMessage:IncomingMessage;

    public function new(incomingMessage:IncomingMessage) {
        this.incomingMessage = incomingMessage;
    }

    public override function readByte():Int {
        return incomingMessage.read(1).readUInt8(0);
    }

    public override function close():Void {

    }
}
#end