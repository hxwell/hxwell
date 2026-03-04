package hx.well.http.driver.socket;

#if (!php && !js)
import hx.well.websocket.AbstractWebSocketHandler;
import hx.well.websocket.WebSocketSession;
import hx.well.http.Request;
import haxe.io.Bytes;
import haxe.crypto.Sha1;
import haxe.crypto.Base64;
import haxe.Exception;
import sys.net.Socket;
import haxe.crypto.random.SecureRandom;
import haxe.crypto.random.SecureRandom.SecureRandom.bytes;

using StringTools;

/**
 * WebSocket implementation for the raw Socket driver.
 *
 * Handles the WebSocket handshake (RFC 6455) and the frame protocol
 * manually, since there is no library to delegate to.
 */
class SocketWebSocketHandler {
    private static inline var WS_MAGIC_STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

    private static function computeWebSocketAccept(key:String):String {
        var concat = key + WS_MAGIC_STRING;
        return Base64.encode(Sha1.make(Bytes.ofString(concat)));
    }

    /**
	 * Performs the WebSocket handshake and then enters the message loop.
	 * This method blocks the current thread until the connection is closed.
	 */
    public static function upgrade(socket:Socket, request:Request, handler:AbstractWebSocketHandler):Void {
        var wsKey = request.header("Sec-WebSocket-Key");
        if(wsKey == null) {
            socket.close();
            return;
        }

        wsKey = wsKey.trim();
        var acceptKey = computeWebSocketAccept(wsKey);

        var responseStr = "HTTP/1.1 101 Switching Protocols\r\n" + "Upgrade: websocket\r\n" + "Connection: Upgrade\r\n" + "Sec-WebSocket-Accept: " + acceptKey + "\r\n" + "Sec-WebSocket-Version: 13\r\n" + "\r\n";

        socket.output.writeString(responseStr);
        socket.output.flush();

        socket.setTimeout(3600);

        // 2. Create session
        var sessionId = generateSessionId();
        var writeMutex = new sys.thread.Mutex();

        var session = new WebSocketSession(sessionId, ()-> {
            sendCloseFrame(socket, writeMutex);
            try {
                socket.close();
            } catch(e:Dynamic) {}
        }, request.queries);

        // Start the send queue worker thread for this session
        var sendWorker = new SocketWebSocketSendWorker(session, socket, writeMutex);
        sendWorker.start();

        handler.addSession(session);

        try {
            handler.onOpen(session);
        } catch(e:Exception) {
            handler.onError(session, e);
        }

        // 3. Enter the message loop
        try {
            messageLoop(socket, handler, session, writeMutex);
        } catch(e:Dynamic) {
            // Connection closed or error
        }

        // 4. Cleanup
        handler.removeSession(sessionId);
        try {
            handler.onClose(session, 1000, "Connection closed");
        } catch(e:Exception) {
            handler.onError(session, e);
        }
        try {
            socket.close();
        } catch(e:Dynamic) {}
    }

    /**
	 * Reads and processes WebSocket frames in a loop until the connection
	 * is closed or an error occurs.
	 */
    private static function messageLoop(socket:Socket, handler:AbstractWebSocketHandler, session:WebSocketSession, writeMutex:sys.thread.Mutex):Void {
        while(true) {
            var frame = readFrame(socket);
            if(frame == null)
                break;

            switch(frame.opcode) {
                case 0x1: // Text frame
                    var text = frame.payload.toString();
                    try {
                        handler.onMessage(session, text);
                    } catch(e:Exception) {
                        handler.onError(session, e);
                    }

                case 0x2: // Binary frame
                    try {
                        handler.onBinary(session, frame.payload);
                    } catch(e:Exception) {
                        handler.onError(session, e);
                    }

                case 0x8: // Close frame
                    var code = 1000;
                    var reason = "";
                    if(frame.payload.length >= 2) {
                        code = (frame.payload.get(0) << 8) | frame.payload.get(1);
                        if(frame.payload.length > 2) {
                            reason = frame.payload.sub(2, frame.payload.length - 2).toString();
                        }
                    }
                    // Send close frame back
                    sendCloseFrame(socket, writeMutex, code);
                    handler.removeSession(session.id);
                    try {
                        handler.onClose(session, code, reason);
                    } catch(e:Exception) {
                        handler.onError(session, e);
                    }
                    return;

                case 0x9: // Ping
                    sendPongFrame(socket, writeMutex, frame.payload);

                case 0xA: // Pong
                // Ignore pong frames

                default:
                // Unknown opcode, ignore
            }
        }
    }

    // -- Frame reading --

    private static function readFrame(socket:Socket):Null<{opcode:Int, payload:Bytes}> {
        try {
            var byte1 = socket.input.readByte();
            var byte2 = socket.input.readByte();

            var opcode = byte1 & 0x0F;
            var masked = (byte2 & 0x80) != 0;
            var payloadLength:Int = byte2 & 0x7F;

            if(payloadLength == 126) {
                payloadLength = (socket.input.readByte() << 8) | socket.input.readByte();
            } else if(payloadLength == 127) {
                // Read 8 bytes for extended payload length (we only support up to Int range)
                var high = 0;
                for(i in 0...4)
                    high = (high << 8) | socket.input.readByte();
                var low = 0;
                for(i in 0...4)
                    low = (low << 8) | socket.input.readByte();
                payloadLength = low; // Assume it fits in an Int
            }

            var maskKey:Bytes = null;
            if(masked) {
                maskKey = Bytes.alloc(4);
                socket.input.readFullBytes(maskKey, 0, 4);
            }

            var payload = Bytes.alloc(payloadLength);
            if(payloadLength > 0) {
                socket.input.readFullBytes(payload, 0, payloadLength);
            }

            // Unmask
            if(masked && maskKey != null) {
                for(i in 0...payloadLength) {
                    payload.set(i, payload.get(i) ^ maskKey.get(i % 4));
                }
            }

            return {opcode: opcode, payload: payload};
        } catch(e:Dynamic) {
            return null;
        }
    }

    // -- Frame writing --

    private static function sendFrame(socket:Socket, writeMutex:sys.thread.Mutex, opcode:Int, payload:Bytes):Void {
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

    private static function sendTextFrame(socket:Socket, writeMutex:sys.thread.Mutex, message:String):Void {
        sendFrame(socket, writeMutex, 0x1, Bytes.ofString(message));
    }

    private static function sendBinaryFrame(socket:Socket, writeMutex:sys.thread.Mutex, data:Bytes):Void {
        sendFrame(socket, writeMutex, 0x2, data);
    }

    private static function sendCloseFrame(socket:Socket, writeMutex:sys.thread.Mutex, code:Int = 1000):Void {
        var payload = Bytes.alloc(2);
        payload.set(0, (code >> 8) & 0xFF);
        payload.set(1, code & 0xFF);

        sendFrame(socket, writeMutex, 0x8, payload);
    }

    private static function sendPongFrame(socket:Socket, writeMutex:sys.thread.Mutex, payload:Bytes):Void {
        sendFrame(socket, writeMutex, 0xA, payload);
    }

    private static function generateSessionId():String {
        return SecureRandom.bytes(16).toHex().toUpperCase();
    }
}
#end
