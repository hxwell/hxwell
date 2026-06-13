package hx.well.http.driver.socket;

#if (!php && !js)
import sys.net.Socket;
import haxe.io.Input;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.driver.IDriverContext;
import haxe.Exception;
import hx.well.io.ChunkedDeflateCompressInput;
import hx.well.http.encoding.DeflateEncodingOptions;
import hx.well.websocket.AbstractWebSocketHandler;
using hx.well.tools.MapTools;
using StringTools;

#if atomic
import haxe.atomic.AtomicInt;
#end

// TODO: Create a case-insensitive map for headers, as HTTP headers are case-insensitive. This will simplify header management and ensure compliance with HTTP standards.
class SocketDriverContext implements IDriverContext {
    // TODO: Make this configurable
    public static var compressedContentTypes:Array<String> = [
        "text/plain",
        "text/css",
        "text/xml",
        "text/html",
        "text/javascript",
        "application/javascript",
        "application/x-javascript",
        "application/json",
        "application/ld+json",
        "application/xml",
        "application/rss+xml",
        "application/atom+xml",
        "application/xhtml+xml",
        "image/svg+xml",
        "font/ttf",
        "font/otf",
        "font/woff",
        "font/woff2",
    ];

    private var driver:SocketDriver;
    private var socket:Socket;
    private var request:Request;
    private var beginWriteCalled:Bool = false;

    #if atomic
    private static var activeConnections:AtomicInt = new AtomicInt(0);
    #end

    private var _input:SocketInput;
    public var input(get, null):SocketInput;
    public inline function get_input():SocketInput {
        return this._input;
    }

    private var _output:SocketOutput;
    @:isVar public var output(get, null):SocketOutput;
    public function get_output():SocketOutput {
        if(!beginWriteCalled)
            throw new Exception("You must call beginWrite first");

        return _output;
    }

    public function new(socket:Socket, driver:SocketDriver) {
        this.socket = socket;
        this.driver = driver;
        this._input = new SocketInput(socket);
        this._output = new SocketOutput(socket);

        #if atomic
        activeConnections.add(1);

        trace("New connection established. Active connections: " + activeConnections.load());
        #end
    }

    private function buildRequest():Request {
        request = SocketRequestParser.parseFromSocket(socket);
        request.context = this;
        return request;
    }

    private function parseBody():Void {
        SocketRequestParser.parseBody(request, input);
    }

    public function writeResponse(response:Response):Void {
        if(beginWriteCalled)
            throw new haxe.Exception("beginWrite() must be called before writeResponse()");

        if (response is AsyncResponse)
            return;

        if (response != null) {
            response.concat(ResponseStatic.get());

            var responseInput:Input = response.toInput();

            if(response.encodingOptions is DeflateEncodingOptions) {
                var acceptEncoding:String = request.header("Accept-Encoding", "");
                var encodings:Array<String> = acceptEncoding.split(",").map(value -> value.trim());

                if(encodings.contains("deflate")) {
                    responseInput = new ChunkedDeflateCompressInput(responseInput, cast response.encodingOptions);
                    response.header("Content-Encoding", "deflate");
                    response.header("Transfer-Encoding", "chunked");
                } else {
                    response.encodingOptions = null;
                }
            }

            socket.output.writeString(generateHeader(response));

            _output.writeInput(responseInput);

            try {
                if (responseInput != null) {
                    responseInput.close();
                }
            } catch (e:Dynamic) {
                // Ignore errors on closing the input, it might already be closed.
            }

            _output.flush();

            if(request != null && request.existsAttribute("is_async_response"))
                close();
        }

        if (response != null && response.after != null)
            response.after();
    }

    public function upgradeToWebSocket(request:Request, handler:AbstractWebSocketHandler):Void {
        SocketWebSocketHandler.upgrade(socket, request, handler);
    }

    public function close():Void {
        #if atomic
        activeConnections.sub(1);
        #end

        if(_output.isKeepAlive) {
            _input.clear();
            _output.close();

            // Prepare for next request
            driver.process(socket);
        }else{
            try {
                socket.close();
            } catch (e:Dynamic) {

            }
        }

        _input = null;
        _output = null;
        socket = null;
    }

    public function beginWrite():Void {
        if (beginWriteCalled)
            return;

        beginWriteCalled = true;

        var header = generateHeader();
        try {
            socket.output.writeString(header);
        } catch (e:Exception) {
            throw new haxe.Exception("Error writing response header: " + e.toString());
        }
    }

    public function writeInput(i:Input, ?bufsize:Int):Void {
        ensureReadyForWrite();
        _output.writeInput(i, bufsize);
    }

    public function writeString(s:String, ?encoding:haxe.io.Encoding):Void {
        ensureReadyForWrite();
        _output.writeString(s, encoding);
    }

    public function writeFullBytes(bytes:haxe.io.Bytes, pos:Int = 0, len:Int = -1):Void {
        ensureReadyForWrite();
        _output.writeFullBytes(bytes, pos, len);
    }

    public function writeByte(c:Int):Void {
        ensureReadyForWrite();
        _output.writeByte(c);
    }

    public function flush():Void {
        _output.flush();
    }

    private inline function ensureReadyForWrite():Void {
        if (!beginWriteCalled) {
            beginWrite();
        }
    }

    private function generateHeader(response:Response = null): String {
        var staticResponse:Response = ResponseStatic.get();
        var finalResponse:Response = response == null ? staticResponse : response;

        var statusCode:Int = (finalResponse.statusCode == null ? 200 : finalResponse.statusCode);
        var statusMessage:String = finalResponse.statusMessage == null ? ResponseStatic.getStatusMessage(statusCode) : finalResponse.statusMessage;

        var responseBuffer:StringBuf = new StringBuf();
        responseBuffer.add("HTTP/1.1 " + statusCode + " " + statusMessage + "\r\n");

        var headers:Map<String, String> = response == null ? staticResponse.headers : response.headers.concat(staticResponse.headers, false);
        var cookies:Map<String, CookieData> = response == null ? staticResponse.cookies : response.cookies.concat(staticResponse.cookies, false);
        var contentLength = response == null ? staticResponse.contentLength : (response.contentLength ?? staticResponse.contentLength);

        for (cookieData in cookies) {
            responseBuffer.add('Set-Cookie: ${cookieData}\r\n');
        }

        for (header in headers.keys()) {
            // Ignore content length header
            if(headers.exists("Content-Length") && header == "Content-Length")
                continue;

            responseBuffer.add(header + ": " + headers.get(header) + "\r\n");
        }

        if(contentLength != null)
        {
            responseBuffer.add('Content-Length: ${contentLength}\r\n');
        }
        else
        {
            // Both encoding and chunked transfer are not compatible, allow only one
            _output.isChunked = finalResponse.encodingOptions == null;
            responseBuffer.add('Transfer-Encoding: chunked\r\n');
        }

        var connection = headers.exists("Connection") ? headers.get("Connection").toLowerCase() : "close";
        switch (connection) {
            case "keep-alive":
                _output.isKeepAlive = true;
        }
        responseBuffer.add('Connection: ${connection}\r\n');

        responseBuffer.add("\r\n");
        return responseBuffer.toString();
    }
}
#end