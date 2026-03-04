package hx.well.websocket;

import haxe.io.Bytes;

/**
 * Represents a message in the WebSocket send queue.
 *
 * Used internally by `WebSocketSession` to queue outgoing messages
 * for asynchronous processing by `WebSocketSendWorker`.
 */
enum WebSocketMessage {
    /** A text message with an optional completion callback. */
    Text(message:String, callback:Null<Void->Void>);

    /** A binary message with an optional completion callback. */
    Binary(data:Bytes, callback:Null<Void->Void>);

    /** Sentinel value to signal the worker thread to shut down. */
    Shutdown;
}
