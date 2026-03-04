package hx.well.websocket;

import haxe.io.Bytes;
import hx.concurrent.collection.Queue;

/**
 * Represents a single WebSocket connection.
 *
 * This class wraps the underlying driver-specific channel and provides
 * a clean API for sending messages, closing the connection, and storing
 * per-session attributes.
 *
 * Messages are sent asynchronously through an internal queue. Each driver
 * provides its own worker thread implementation that processes the queue
 * and performs the actual I/O.
 *
 * Optional callbacks can be provided to `send` and `sendBinary` to be
 * notified when a message has been written to the underlying channel.
 */
class WebSocketSession {
    public var id(default, null):String;

    private var attributes:Map<String, Dynamic> = new Map();

    /** The incoming URL query parameters for this connection. */
    public var queryParams(default, null):Map<String, String>;

    /** The outgoing message queue processed by the driver's worker thread. */
    public var queue(default, null):Queue<WebSocketMessage>;

    private var _close:Void->Void;

    public function new(id:String, close:Void->Void, ?queryParams:Map<String, String>) {
        this.id = id;
        this._close = close;
        this.queue = new Queue<WebSocketMessage>();
        this.queryParams = queryParams ?? new Map();
    }

    /**
	 * Sends a text message to this WebSocket client.
	 *
	 * The message is queued and sent asynchronously by the driver's worker thread.
	 *
	 * @param message The text message to send.
	 * @param callback Optional callback invoked after the message is sent.
	 */
    public function send(message:String, ?callback:Void->Void):Void {
        queue.push(WebSocketMessage.Text(message, callback));
    }

    /**
	 * Sends a binary message to this WebSocket client.
	 *
	 * The message is queued and sent asynchronously by the driver's worker thread.
	 *
	 * @param data The binary data to send.
	 * @param callback Optional callback invoked after the message is sent.
	 */
    public function sendBinary(data:Bytes, ?callback:Void->Void):Void {
        queue.push(WebSocketMessage.Binary(data, callback));
    }

    /**
	 * Closes this WebSocket connection.
	 *
	 * The underlying driver worker should be stopped separately via `shutdown()`.
	 */
    public function close():Void {
        shutdown();
        _close();
    }

    /**
	 * Shuts down the send queue by pushing a Shutdown sentinel.
	 *
	 * Called internally when the session is removed (e.g., on remote disconnect).
	 * This wakes up the driver's worker thread and signals it to exit.
	 * Safe to call multiple times.
	 */
    public function shutdown():Void {
        queue.push(WebSocketMessage.Shutdown);
    }

    /**
	 * Gets a per-session attribute.
	 */
    public function getAttribute<T>(key:String):Null<T> {
        return attributes.get(key);
    }

    /**
	 * Sets a per-session attribute.
	 */
    public function setAttribute(key:String, value:Dynamic):Void {
        attributes.set(key, value);
    }
}
