package hx.well.websocket.socketio;

import haxe.Json;
import hx.well.websocket.WebSocketSession;

/**
 * A Socket.IO-style session wrapper around WebSocketSession.
 *
 * Provides event-based communication (`emit`, `on`) and room support
 * (`join`, `leave`, `to`) similar to the Socket.IO API.
 *
 * Messages are serialized as JSON: `{"event":"name","data":...}`
 *
 * Example:
 * ```haxe
 * socket.on("chat:message", (data) -> {
 *     socket.emit("chat:reply", {text: "Received!"});
 *     socket.to("lobby").emit("chat:message", data);
 * });
 * socket.join("lobby");
 * ```
 */
class SocketIOSession {
    public var id(default, null):String;

    /** The underlying raw WebSocket session. */
    public var raw(default, null):WebSocketSession;

    /** Rooms this session has joined. */
    public var rooms(default, null):Array<String> = [];

    private var listeners:Map<String, Array<Dynamic->Void>> = new Map();
    private var handler:SocketIOHandler;
    private var connected:Bool = false;

    public function new(wsSession:WebSocketSession, handler:SocketIOHandler) {
        this.id = wsSession.id;
        this.raw = wsSession;
        this.handler = handler;
    }

    /** Returns true if Socket.IO connection handshake is complete. */
    public function _isConnected():Bool {
        return connected;
    }

    /** Marks the Socket.IO connection as established. */
    public function _setConnected():Void {
        connected = true;
    }

    // -- Event API --

    /**
	 * Registers a listener for the given event name.
	 * Multiple listeners can be registered for the same event.
	 */
    public function on(event:String, callback:Dynamic->Void):Void {
        if(!listeners.exists(event)) {
            listeners.set(event, []);
        }
        listeners.get(event).push(callback);
    }

    /**
	 * Removes all listeners for the given event.
	 */
    public function off(event:String):Void {
        listeners.remove(event);
    }

    /**
	 * Emits an event with data to this client.
	 */
    public function emit(event:String, ?data:Dynamic):Void {
        raw.send("42" + Json.stringify([event, data]));
    }

    // -- Room API --

    /**
	 * Joins a room. A session can be in multiple rooms simultaneously.
	 */
    public function join(room:String):Void {
        if(!Lambda.has(rooms, room)) {
            rooms.push(room);
        }
        handler._addToRoom(room, this);
    }

    /**
	 * Leaves a room.
	 */
    public function leave(room:String):Void {
        rooms.remove(room);
        handler._removeFromRoom(room, this);
    }

    /**
	 * Returns a RoomEmitter for sending events to a specific room.
	 * Usage: `socket.to("lobby").emit("event", data);`
	 */
    public function to(room:String):RoomEmitter {
        return new RoomEmitter(handler, room, this);
    }

    /**
	 * Emits an event to all connected clients EXCEPT this session.
	 */
    public function broadcastEmit(event:String, ?data:Dynamic):Void {
        var message = "42" + Json.stringify([event, data]);
        for(session in handler.getSockets()) {
            if(session.id != this.id) {
                session.raw.send(message);
            }
        }
    }

    /**
	 * Closes this connection.
	 */
    public function close():Void {
        raw.close();
    }

    /**
	 * Gets a per-session attribute.
	 */
    public function getAttribute<T>(key:String):Null<T> {
        return raw.getAttribute(key);
    }

    /**
	 * Sets a per-session attribute.
	 */
    public function setAttribute(key:String, value:Dynamic):Void {
        raw.setAttribute(key, value);
    }

    // -- Internal --

    /**
	 * Dispatches a received event to registered listeners.
	 */
    public function _dispatch(event:String, data:Dynamic):Void {
        var callbacks = listeners.get(event);
        if(callbacks != null) {
            for(callback in callbacks) {
                callback(data);
            }
        }
    }
}

/**
 * Helper class for emitting events to a specific room.
 * Created via `socket.to("room")`.
 */
class RoomEmitter {
    private var handler:SocketIOHandler;
    private var room:String;
    private var excludeSession:SocketIOSession;

    public function new(handler:SocketIOHandler, room:String, ?excludeSession:SocketIOSession) {
        this.handler = handler;
        this.room = room;
        this.excludeSession = excludeSession;
    }

    /**
	 * Emits an event to all sessions in the room (excluding the sender if applicable).
	 */
    public function emit(event:String, ?data:Dynamic):Void {
        handler._emitToRoom(room, event, data, excludeSession);
    }
}
