package hx.well.http.driver.undertow;

#if java
import hx.well.websocket.WebSocketMessage;
import hx.well.websocket.WebSocketSession;
import hx.well.http.driver.undertow.UndertowWebSocketExtern;
import hx.concurrent.collection.Queue;
import haxe.io.Bytes;
import java.nio.ByteBuffer;

/**
 * Undertow-specific WebSocket send queue worker.
 *
 * Processes the session's outgoing message queue in a dedicated thread,
 * using Undertow's `WebSocketsExtern.sendText` / `sendBinary` API
 * to write messages to the underlying channel.
 *
 * One instance per WebSocket session is created by `UndertowWebSocketCallback`.
 */
class UndertowWebSocketSendWorker {
    private var session:WebSocketSession;
    private var channel:WebSocketChannelExtern;
    private var running:Bool = false;

    /**
	 * Creates a new Undertow send worker.
	 *
	 * @param session The WebSocket session whose queue will be processed.
	 * @param channel The Undertow WebSocket channel to write to.
	 */
    public function new(session:WebSocketSession, channel:WebSocketChannelExtern) {
        this.session = session;
        this.channel = channel;
    }

    /**
	 * Starts the worker in a new thread.
	 *
	 * The thread blocks on the session's queue (`pop(-1)`) and
	 * sends messages through the Undertow channel as they arrive.
	 */
    public function start():Void {
        if(running)
            return;

        running = true;

        sys.thread.Thread.create(()-> {
            processLoop();
        });
    }

    /**
	 * Main processing loop. Blocks on the queue and dispatches messages
	 * through the Undertow WebSockets API.
	 */
    private function processLoop():Void {
        while(running) {
            var msg = session.queue.pop(-1);

            if(msg == null)
                continue;

            switch(msg) {
                case Text(message, callback):
                    try {
                        WebSocketsExtern.sendText(message, channel, null);
                        if(callback != null)
                            callback();
                    } catch(e:Dynamic) {
                        trace("[UndertowWebSocketSendWorker] Send text error: " + e);
                        running = false;
                        try
                        channel.close() catch(_:Dynamic) {}
                    }

                case Binary(data, callback):
                    try {
                        var buffer = ByteBuffer.wrap(data.getData());
                        WebSocketsExtern.sendBinary(buffer, channel, null);
                        if(callback != null)
                            callback();
                    } catch(e:Dynamic) {
                        trace("[UndertowWebSocketSendWorker] Send binary error: " + e);
                        running = false;
                        try
                        channel.close() catch(_:Dynamic) {}
                    }

                case Shutdown:
                    running = false;
            }
        }
    }

    /**
	 * Stops the worker thread gracefully.
	 *
	 * Pushes a `Shutdown` sentinel to wake up the blocking `pop(-1)`
	 * and exit the processing loop.
	 */
    public function stop():Void {
        if(!running)
            return;

        running = false;
        session.queue.push(WebSocketMessage.Shutdown);
    }
}
#end
