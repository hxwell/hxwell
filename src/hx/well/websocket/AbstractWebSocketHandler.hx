package hx.well.websocket;

import haxe.io.Bytes;
import haxe.Exception;
import hx.concurrent.collection.SynchronizedMap;
import hx.well.http.Request;
import hx.well.http.Response;

/**
 * Base class for WebSocket handlers.
 *
 * Extend this class and override the lifecycle methods to handle
 * WebSocket events. Register it with `Route.websocket("/path").handler(handler)`.
 *
 * Example:
 * ```haxe
 * class ChatHandler extends AbstractWebSocketHandler {
 *     override function onOpen(session:WebSocketSession):Void {
 *         trace("Connected: " + session.id);
 *     }
 *
 *     override function onMessage(session:WebSocketSession, message:String):Void {
 *         // Broadcast to all connected clients
 *         for (s in getSessions()) {
 *             s.send(message);
 *         }
 *     }
 * }
 * ```
 */
abstract class AbstractWebSocketHandler {
    private var sessions = SynchronizedMap.newStringMap();

    public function new() {}

    // -- Lifecycle callbacks (override these) --

    /**
	 * Called when a new WebSocket connection is established.
	 */
    public abstract function onOpen(session:WebSocketSession):Void;

    /**
	 * Called when a text message is received from the client.
	 */
    public abstract function onMessage(session:WebSocketSession, message:String):Void;

    /**
	 * Called when a binary message is received from the client.
	 */
    public abstract function onBinary(session:WebSocketSession, data:Bytes):Void;

    /**
	 * Called when the WebSocket connection is closed.
	 */
    public abstract function onClose(session:WebSocketSession, code:Int, reason:String):Void;

    /**
	 * Called when an error occurs on the WebSocket connection.
	 */
    public abstract function onError(session:WebSocketSession, error:Exception):Void;

    /**
	 * Called when a normal HTTP GET request hits this WebSocket route.
	 * Returns a Response if handled, or null to skip/continue to 404.
	 */
    public function onGet(request:Request):Null<Response> {
        return null;
    }

    /**
	 * Called when a normal HTTP POST request hits this WebSocket route.
	 * Returns a Response if handled, or null to skip/continue to 404.
	 */
    public function onPost(request:Request):Null<Response> {
        return null;
    }

    // -- Session management (used by drivers) --

    /**
	 * Registers a session. Called by the driver when a new connection is established.
	 */
    public function addSession(session:WebSocketSession):Void {
        sessions.set(session.id, session);
    }

    /**
	 * Removes a session. Called by the driver when a connection is closed.
	 */
    public function removeSession(sessionId:String):Void {
        var session = sessions.get(sessionId);
        if(session != null) {
            session.shutdown();
        }
        sessions.remove(sessionId);
    }

    /**
	 * Returns a specific session by ID, or null if not found.
	 */
    public function getSession(sessionId:String):Null<WebSocketSession> {
        return sessions.get(sessionId);
    }

    /**
	 * Returns an iterator over all active sessions.
	 */
    public function getSessions():Iterator<WebSocketSession> {
        return sessions.iterator();
    }

    /**
	 * Sends a text message to all connected clients.
	 */
    public function broadcast(message:String):Void {
        // iterate on a copy to avoid concurrent modification issues
        var socks = [for(s in sessions.copy()) s];
        for(session in socks) {
            session.send(message);
        }
    }

    /**
	 * Sends a binary message to all connected clients.
	 */
    public function broadcastBinary(data:Bytes):Void {
        var socks = [for(s in sessions.copy()) s];
        for(session in socks) {
            session.sendBinary(data);
        }
    }
}
