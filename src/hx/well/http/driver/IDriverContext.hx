package hx.well.http.driver;

import hx.well.http.Request;
import hx.well.http.Response;
import haxe.io.Input;
import haxe.io.Output;

/**
 * Defines the contract for a driver-specific context for a single HTTP request.
 *
 * This interface abstracts away the underlying server implementation (e.g., Socket, Undertow)
 * from the main HttpHandler. It is responsible for all I/O operations and for translating
 * native request/response objects into the framework's common objects.
 *
 * It provides two mutually exclusive ways to send a response:
 * 1. `writeResponse(response)`: For simple, buffered responses that are sent in one go.
 * 2. `beginWrite()` followed by `write*` methods: For manual/streaming responses.
 */
@:allow(hx.well.http.HttpHandler)
interface IDriverContext {
    /**
     * Input stream used to read the request body.
     */
    @:isVar public var input(get, null):Input;

    /**
     * Output stream used to write the response to the client.
     */
    @:isVar public var output(get, null):Output;

    /**
     * Builds the framework's common `Request` object from the driver's
     * native request data.
     * @return The populated `Request` object.
     */
    private function buildRequest():Request;

    /**
     * Parses the body of the incoming request and populates the `Request` object.
     * This is typically called only for non-streaming requests.
     */
    private function parseBody():Void;

    /**
     * Writes a complete `Response` object to the client in a single operation.
     * This method should not be used if a manual stream has been started with `beginWrite()`.
     * @param response The complete `Response` object to send.
     */
    function writeResponse(response:Response):Void;

    /**
     * Begins a manual/streaming response. This sends the HTTP status line and headers,
     * preparing the stream for the body content. This must be called before any `write*` methods
     * are used for streaming.
     */
    function beginWrite():Void;

    /**
     * Writes the content of an `Input` stream to the response body.
     * Requires `beginWrite()` to have been called first.
     * @param i The `Input` stream to read from.
     * @param bufsize The size of the buffer to use for copying.
     */
    function writeInput(i:Input, ?bufsize:Int):Void;

    /**
     * Writes a string to the response body.
     * Requires `beginWrite()` to have been called first.
     * @param s The `String` to write.
     * @param encoding The character encoding to use.
     */
    function writeString(s:String, ?encoding:haxe.io.Encoding):Void;

    /**
     * Writes a chunk of bytes to the response body.
     * Requires `beginWrite()` to have been called first.
     * @param bytes The `Bytes` buffer to write from.
     * @param pos The starting position in the buffer.
     * @param len The number of bytes to write.
     */
    function writeFullBytes(bytes:haxe.io.Bytes, pos:Int = 0, len:Int = -1):Void;

    /**
     * Writes a single byte to the response body.
     * Requires `beginWrite()` to have been called first.
     * @param c The byte to write.
     */
    function writeByte(c:Int):Void;

    /**
     * Flushes any buffered output to the client.
     */
    function flush():Void;

    /**
     * Closes the connection and releases all resources associated with this request context.
     * This should be the final action for any request.
     */
    function close():Void;
}