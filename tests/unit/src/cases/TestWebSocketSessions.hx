package cases;

import haxe.Exception;
import haxe.io.Bytes;
import hx.well.websocket.AbstractWebSocketHandler;
import hx.well.websocket.WebSocketSession;
import utest.Assert;
import utest.Test;

class TestWebSocketSessions extends Test {
    function testSessionIteratorIsASnapshot() {
        var handler = new SnapshotHandler();
        handler.addSession(new WebSocketSession("first", () -> {}));
        handler.addSession(new WebSocketSession("second", () -> {}));

        var sessions = handler.getSessions();
        handler.removeSession("first");

        var originalIds = [for (session in sessions) session.id];
        Assert.equals(2, originalIds.length);
        Assert.isTrue(originalIds.contains("first"));
        Assert.same(["second"], [for (session in handler.getSessions()) session.id]);
    }
}

private class SnapshotHandler extends AbstractWebSocketHandler {
    public function onOpen(session:WebSocketSession):Void {}
    public function onMessage(session:WebSocketSession, message:String):Void {}
    public function onBinary(session:WebSocketSession, data:Bytes):Void {}
    public function onClose(session:WebSocketSession, code:Int, reason:String):Void {}
    public function onError(session:WebSocketSession, error:Exception):Void {}
}
