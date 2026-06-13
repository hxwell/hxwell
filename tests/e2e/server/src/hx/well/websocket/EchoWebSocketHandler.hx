package hx.well.websocket;

import haxe.Exception;
import haxe.io.Bytes;

class EchoWebSocketHandler extends AbstractWebSocketHandler {
    public function onOpen(session:WebSocketSession):Void {}

    public function onMessage(session:WebSocketSession, message:String):Void {
        session.send("echo:" + message);
    }

    public function onBinary(session:WebSocketSession, data:Bytes):Void {}

    public function onClose(session:WebSocketSession, code:Int, reason:String):Void {}

    public function onError(session:WebSocketSession, error:Exception):Void {}
}
