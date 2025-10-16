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
import haxe.io.Output;
using hx.well.tools.MapTools;
using StringTools;

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

    private var socket:Socket;
    private var request:Request;
    private var beginWriteCalled:Bool = false;

    @:isVar public var input(get, null):Input;
    public inline function get_input():Input {
        return this.input;
    }

    @:isVar public var output(get, null):Output;
    public function get_output():Output {
        if(!beginWriteCalled)
            throw new Exception("You must call beginWrite first");

        return output;
    }

    public function new(socket:Socket) {
        this.socket = socket;
        this.input = socket.input;
        this.output = socket.output;
    }

    private function buildRequest():Request {
        request = SocketRequestParser.parseFromSocket(socket);
        request.context = this;
        return request;
    }

    private function parseBody():Void {
        SocketRequestParser.parseBody(request, socket.input);
    }

    public function writeResponse(response:Response):Void {
        if(beginWriteCalled)
            throw new haxe.Exception("beginWrite() must be called before writeResponse()");

        if (response is AsyncResponse)
            return;

        if (response != null) {
            response.concat(ResponseStatic.get());

            var acceptEncoding:String = request.header("Accept-Encoding", "");
            var encodings:Array<String> = acceptEncoding.split(",").map(value -> value.trim());

            /*if(encodings.contains("deflate"))
            {
                var contentType:String = response.headers.get("Content-Type");

                if(contentType != null && response.encodingOptions == null) {
                    if(compressedContentTypes.contains(contentType))
                        response.encodingOptions = new DeflateEncodingOptions(1, 64 * 1024);
                }

                if(response.encodingOptions is DeflateEncodingOptions) {
                    response.header("Content-Encoding", "deflate");
                    response.header("Transfer-Encoding", "chunked");
                    trace("Using Deflate encoding for response");
                }
            }else{
                if(response.encodingOptions is DeflateEncodingOptions) {
                    response.encodingOptions = null;
                }
            }*/

            var responseInput:Input = response.toInput();

            if(response.encodingOptions is DeflateEncodingOptions) {
                responseInput = new ChunkedDeflateCompressInput(responseInput, cast response.encodingOptions);
                response.header("Content-Encoding", "deflate");
                response.header("Transfer-Encoding", "chunked");
            }

            socket.output.writeString(generateHeader(response));

            try {
                socket.output.writeInput(responseInput);
                trace("Response written for path: " + request.path);
            } catch (e) {
                throw e;
            }

            try {
                if (responseInput != null) {
                    responseInput.close();
                }
            } catch (e:Dynamic) {
                // Ignore errors on closing the input, it might already be closed.
            }

            socket.output.flush();
            socket.output.close();
        }

        if (response != null && response.after != null)
            response.after();
    }

    public function close():Void {
        try {
            socket.output.close();
            socket.close();
        } catch (e:Dynamic) {
            // Socket zaten kapalı olabilir, görmezden gel.
        }
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
        socket.output.writeInput(i, bufsize);
    }

    public function writeString(s:String, ?encoding:haxe.io.Encoding):Void {
        ensureReadyForWrite();
        socket.output.writeString(s, encoding);
    }

    public function writeFullBytes(bytes:haxe.io.Bytes, pos:Int = 0, len:Int = -1):Void {
        ensureReadyForWrite();
        socket.output.writeFullBytes(bytes, pos, len);
    }

    public function writeByte(c:Int):Void {
        ensureReadyForWrite();
        socket.output.writeByte(c);
    }

    public function flush():Void {
        socket.output.flush();
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

        var cookieResponse:String = "";
        for(key in cookies.keys())
        {
            var cookieData = cookies.get(key);
            cookieResponse += '${cookieData};';
        }
        if(cookieResponse != "")
            headers.set("Set-Cookie", cookieResponse);

        for (header in headers.keys()) {
            // Ignore content length header
            if(headers.exists("Content-Length") && header == "Content-Length")
                continue;

            responseBuffer.add(header + ": " + headers.get(header) + "\r\n");
        }

        if(contentLength != null)
            responseBuffer.add('Content-Length: ${contentLength}\r\n');
        responseBuffer.add("\r\n");
        return responseBuffer.toString();
    }
}
#end