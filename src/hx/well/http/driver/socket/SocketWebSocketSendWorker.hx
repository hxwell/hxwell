package hx.well.http.driver.socket;

#if (!php && !js)
import hx.well.websocket.WebSocketMessage;
import hx.well.websocket.WebSocketSession;
import hx.concurrent.collection.Queue;
import haxe.io.Bytes;
import sys.net.Socket;

/**
 * Socket driver-specific WebSocket send queue worker.
 *
 * Processes the session's outgoing message queue in a dedicated thread,
 * using raw socket frame writing to send WebSocket messages.
 *
 * One instance per WebSocket session is created by `SocketWebSocketHandler`.
 */
class SocketWebSocketSendWorker {
    private var session:WebSocketSession;
    private var socket:Socket;
    private var writeMutex:sys.thread.Mutex;
    private var running:Bool = false;

    /**
	 * Creates a new Socket send worker.
	 *
	 * @param session The WebSocket session whose queue will be processed.
	 * @param socket The underlying TCP socket.
	 * @param writeMutex Mutex for thread-safe socket writes.
	 */
    public function new(session:WebSocketSession, socket:Socket, writeMutex:sys.thread.Mutex) {
        this.session = session;
        this.socket = socket;
        this.writeMutex = writeMutex;
    }

    /**
	 * Starts the worker in a new thread.
	 *
	 * The thread blocks on the session's queue (`pop(-1)`) and
	 * sends WebSocket frames through the raw socket.
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
	 * Main processing loop. Blocks on the queue and writes WebSocket frames.
	 */
    private function processLoop():Void {
        while(running) {
            var msg = session.queue.pop(-1);

            if(msg == null)
                continue;

            switch(msg) {
                case Text(message, callback):
                    try {
                        sendFrame(0x1, Bytes.ofString(message));
                        if(callback != null)
                            callback();
                    } catch(e:Dynamic) {
                        trace("[SocketWebSocketSendWorker] Send text error: " + e);
                        running = false;
                        try
                        socket.close() catch(_:Dynamic) {}
                    }

                case Binary(data, callback):
                    try {
                        sendFrame(0x2, data);
                        if(callback != null)
                            callback();
                    } catch(e:Dynamic) {
                        trace("[SocketWebSocketSendWorker] Send binary error: " + e);
                        running = false;
                        try
                        socket.close() catch(_:Dynamic) {}
                    }

                case Shutdown:
                    running = false;
            }
        }
    }

    /**
	 * Writes a WebSocket frame (FIN + opcode + payload) to the socket.
	 */
    private function sendFrame(opcode:Int, payload:Bytes):Void {
        var length = payload.length;

        writeMutex.acquire();
        try {
            // FIN + opcode
            socket.output.writeByte(0x80 | opcode);

            // Payload length (server to client is NOT masked)
            if(length < 126) {
                socket.output.writeByte(length);
            } else if(length < 65536) {
                socket.output.writeByte(126);
                socket.output.writeByte((length >> 8) & 0xFF);
                socket.output.writeByte(length & 0xFF);
            } else {
                socket.output.writeByte(127);
                // 8 bytes for length
                for(i in 0...4)
                    socket.output.writeByte(0);
                socket.output.writeByte((length >> 24) & 0xFF);
                socket.output.writeByte((length >> 16) & 0xFF);
                socket.output.writeByte((length >> 8) & 0xFF);
                socket.output.writeByte(length & 0xFF);
            }

            socket.output.writeFullBytes(payload, 0, length);
            socket.output.flush();
        } catch(e:Dynamic) {
            // Ignored
        }
        writeMutex.release();
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
