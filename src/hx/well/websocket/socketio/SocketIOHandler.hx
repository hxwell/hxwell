package hx.well.websocket.socketio;

import haxe.Json;
import haxe.io.Bytes;
import haxe.Exception;
import hx.well.websocket.AbstractWebSocketHandler;
import hx.well.websocket.WebSocketSession;
import hx.concurrent.collection.SynchronizedMap;
import hx.concurrent.collection.SynchronizedArray;
import hx.well.websocket.socketio.SocketIOSession.RoomEmitter;
import hx.well.http.ResponseBuilder;

using StringTools;

/**
 * A Socket.IO-style handler built on top of AbstractWebSocketHandler.
 *
 * Provides event-based communication and room/channel support similar
 * to Socket.IO. Messages are automatically serialized/deserialized as JSON
 * with the format: `{"event":"name","data":...}`
 *
 * Usage:
 * ```haxe
 * class ChatHandler extends SocketIOHandler {
 *     override function onConnection(socket:SocketIOSession):Void {
 *         socket.on("chat:message", (data) -> {
 *             // Echo back to sender
 *             socket.emit("chat:reply", data);
 *
 *             // Broadcast to all in room except sender
 *             socket.to("lobby").emit("chat:message", data);
 *         });
 *
 *         socket.join("lobby");
 *         socket.emit("welcome", {message: "Welcome!"});
 *     }
 *
 *     override function onDisconnect(socket:SocketIOSession):Void {
 *         trace("Disconnected: " + socket.id);
 *     }
 * }
 *
 * // Route registration
 * Route.websocket("/ws/chat").setWsHandler(new ChatHandler());
 * ```
 */
abstract class SocketIOHandler extends AbstractWebSocketHandler {
    /** All active SocketIO sessions keyed by internal session ID (WebSocket session.id). */
    private var sockets = SynchronizedMap.newStringMap();

    /** Pending handshake tokens from polling: token -> {timestamp, ip}. */
    private var pendingTokens = SynchronizedMap.newStringMap();

    /** Maps client sid (handshake token) to session.id for polling fallback. */
    private var sidToSessionId = SynchronizedMap.newStringMap();

    /** How long a pending token is valid (ms). Default 30 seconds. */
    private var pendingTokenTTL:Float = 30000;

    /** Room membership: room name -> array of sessions. */
    private var rooms = SynchronizedMap.newStringMap();

    public function new() {
        super();
    }

    // -- Lifecycle callbacks (override these) --

    /**
	 * Called when a new client connects.
	 * Register event listeners on the socket here.
	 */
    public abstract function onConnection(socket:SocketIOSession):Void;

    /**
	 * Called when a client disconnects.
	 */
    public abstract function onDisconnect(socket:SocketIOSession):Void;

    // -- Server-level API --

    /**
	 * Emits an event to ALL connected clients.
	 */
    public function emitAll(event:String, ?data:Dynamic):Void {
        var message = "42" + Json.stringify([event, data]);

        var socks = [for(s in sockets.copy()) s];

        for(socket in socks) {
            socket.raw.send(message);
        }
    }

    /**
	 * Emits an event to all clients in a specific room.
	 */
    public function toRoom(room:String):SocketIOSession.RoomEmitter {
        return new SocketIOSession.RoomEmitter(this, room, null);
    }

    /**
	 * Returns an iterator over all active SocketIOSessions.
	 */
    public function getSockets():Iterator<SocketIOSession> {
        var arr = [for(s in sockets.copy()) s];
        return arr.iterator();
    }

    /**
	 * Returns a specific socket by ID.
	 */
    public function getSocket(id:String):Null<SocketIOSession> {
        return sockets.get(id);
    }

    /**
	 * Returns all sessions in a specific room.
	 */
    public function getRoomSessions(room:String):Array<SocketIOSession> {
        var roomSessions:SynchronizedArray<SocketIOSession> = cast rooms.get(room);
        return roomSessions != null ? roomSessions.toArray() : [];
    }

    // -- HTTP Fallback (Socket.IO Polling) --

    override public function onGet(request:hx.well.http.Request):Null<hx.well.http.Response> {
        var transport = request.query("transport");

        if(transport == "polling") {
            var token = request.query("sid");

            if(token == null) {
                // 1. Initial Handshake Request (Engine.IO OPEN packet)
                // Generate a one-time handshake token (NOT the actual session ID)
                var handshakeToken = haxe.crypto.random.SecureRandom.bytes(16).toHex().toLowerCase();

                // Track token with timestamp and client IP for security
                pendingTokens.set(handshakeToken, {
                    timestamp: Date.now().getTime(), ip: request.ip
                });

                var responseStr = haxe.Json.stringify({
                    sid: handshakeToken, upgrades: ["websocket"], pingInterval: 25000, pingTimeout: 20000, maxPayload: 1000000
                });

                // '0' prefix is Engine.IO's OPEN packet
                return ResponseBuilder.asString("0" + responseStr, 200).header("Content-Type", "text/plain; charset=UTF-8");
            } else {
                // 2. Client is polling for data after handshake
                var sessionId = sidToSessionId.get(token);
                var hasValidSession = (sessionId != null && sockets.exists(sessionId));
                if(!pendingTokens.exists(token) && !hasValidSession) {
                    return ResponseBuilder.asString("1", 200).header("Content-Type", "text/plain; charset=UTF-8");
                }
                return ResponseBuilder.asString("6", 200).header("Content-Type", "text/plain; charset=UTF-8");
            }
        }

        return null;
    }

    override public function onPost(request:hx.well.http.Request):Null<hx.well.http.Response> {
        var transport = request.query("transport");
        var sid = request.query("sid");

        if(transport == "polling" && sid != null) {
            // Client is sending data via POST polling
            var body = request.bodyBytes != null ? request.bodyBytes.toString() : "";

            // Normally we would parse Engine.IO packets here and dispatch them
            // For basic ping-pong or to just accept the packet:
            return ResponseBuilder.asString("ok", 200).header("Content-Type", "text/plain; charset=UTF-8");
        }

        return null;
    }

    // -- AbstractWebSocketHandler overrides (internal wiring) --

    public function onOpen(session:WebSocketSession):Void {
        var handshakeToken = session.queryParams.get("sid");
        var isUpgrade = handshakeToken != null;

        // Prevent duplicate sessions for the same WebSocket connection
        if(sockets.exists(session.id)) {
            trace("Duplicate WebSocket session: " + session.id);
            session.close();
            return;
        }

        if(isUpgrade) {
            // Verify the handshake token from polling
            var tokenData:Dynamic = pendingTokens.get(handshakeToken);

            if(tokenData == null) {
                trace("Invalid or expired handshake token: " + handshakeToken);
                session.close();
                return;
            }

            // Check token expiration
            var now = Date.now().getTime();
            if(now - tokenData.timestamp > pendingTokenTTL) {
                trace("Expired handshake token: " + handshakeToken);
                pendingTokens.remove(handshakeToken);
                session.close();
                return;
            }

            pendingTokens.remove(handshakeToken);

            var socket = new SocketIOSession(session, this);
            sockets.set(session.id, socket);
            sidToSessionId.set(handshakeToken, session.id);
            session.setAttribute("handshakeToken", handshakeToken);

            // Client will send probe (2probe) then upgrade (5).
            // We handle those in onMessage and complete the connection there.
        } else {
            // Fresh connection directly on WebSocket (no prior polling handshake)
            var socket = new SocketIOSession(session, this);
            sockets.set(session.id, socket);

            // EIO Open - send our internal session.id as the sid
            var handshake = haxe.Json.stringify({
                sid: session.id, upgrades: [], pingInterval: 25000, pingTimeout: 20000
            });
            session.send("0" + handshake);

            // SIO Connect
            session.send("40" + haxe.Json.stringify({sid: session.id}));
            socket._setConnected();

            try {
                onConnection(socket);
            } catch(e:Exception) {
                trace("Error in onConnection: " + e);
            }
        }
    }

    public function onMessage(session:WebSocketSession, message:String):Void {
        var socket = sockets.get(session.id);
        if(socket == null)
            return;

        if(message.startsWith("2")) {
            // Engine.IO Ping -> Pong (handles both "2" pings and "2probe")
            session.send("3" + message.substring(1));
            return;
        }

        if(message == "5") {
            // Engine.IO Upgrade packet - transport upgrade complete
            // Now we need to send Socket.IO CONNECT and trigger onConnection
            if(!socket._isConnected()) {
                // Send our internal session.id as the sid
                session.send("40" + haxe.Json.stringify({sid: session.id}));
                socket._setConnected();

                try {
                    onConnection(socket);
                } catch(e:Exception) {
                    trace("Error in onConnection: " + e);
                }
            }
            return;
        }

        if(message.startsWith("42")) {
            // Socket.IO Event: 4 (Message) + 2 (Event)
            try {
                var jsonStr = message.substring(2);
                var parsed:Array<Dynamic> = Json.parse(jsonStr);
                var event:String = parsed[0];
                var data:Dynamic = parsed.length > 1 ? parsed[1] : null;

                if(event != null) {
                    socket._dispatch(event, data);
                }
            } catch(e:Exception) {
                socket._dispatch("message", message);
            }
            return;
        }

        socket._dispatch("message", message);
    }

    public function onBinary(session:WebSocketSession, data:Bytes):Void {
        // SocketIO normally handles binary within special packets,
        // but since this is a basic abstraction, we just ignore raw binary for now.
    }

    public function onClose(session:WebSocketSession, code:Int, reason:String):Void {
        var socket = sockets.get(session.id);

        if(socket == null)
            return;

        var handshakeToken:String = session.getAttribute("handshakeToken");
        if(handshakeToken != null) {
            sidToSessionId.remove(handshakeToken);
        }

        for(room in socket.rooms) {
            _removeFromRoom(room, socket);
        }

        sockets.remove(session.id);

        try {
            onDisconnect(socket);
        } catch(e:Exception) {
            trace("Error in onDisconnect: " + e);
        }
    }

    public function onError(session:WebSocketSession, error:Exception):Void {
        var socket = sockets.get(session.id);

        if(socket != null) {
            socket._dispatch("error", error);
        }
    }

    // -- Room management (used internally by SocketIOSession) --

    public function _addToRoom(room:String, socket:SocketIOSession):Void {
        var roomSessions:SynchronizedArray<SocketIOSession> = cast rooms.get(room);
        if(roomSessions == null) {
            roomSessions = new SynchronizedArray();
            rooms.set(room, roomSessions);
        }
        roomSessions.addIfAbsent(socket);
    }

    public function _removeFromRoom(room:String, socket:SocketIOSession):Void {
        var roomSessions:SynchronizedArray<SocketIOSession> = cast rooms.get(room);
        if(roomSessions != null) {
            roomSessions.remove(socket);
            if(roomSessions.isEmpty()) {
                rooms.remove(room);
            }
        }
    }

    public function _emitToRoom(room:String, event:String, data:Dynamic, ?exclude:SocketIOSession):Void {
        var roomSessions:SynchronizedArray<SocketIOSession> = cast rooms.get(room);

        if(roomSessions == null || roomSessions.isEmpty())
            return;

        var socks = roomSessions.toArray();
        var message = "42" + Json.stringify([event, data]);
        for(socket in socks) {
            if(exclude != null && socket.id == exclude.id)
                continue;
            socket.raw.send(message);
        }
    }
}
