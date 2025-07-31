package hx.well.http.driver.nodehttp;

#if js
import haxe.Exception;
import haxe.io.Input;
import haxe.io.Output;
import hx.well.http.driver.IDriverContext;
import hx.well.http.encoding.DeflateEncodingOptions;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.io.ChunkedDeflateCompressInput;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import hx.well.http.driver.socket.SocketRequestParser;
import js.node.Url;
import js.Lib;
import StringTools;
using hx.well.tools.MapTools;
using StringTools;

class NodeHttpDriverContext implements IDriverContext {
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

    private var incomingMessage:IncomingMessage;
    private var serverResponse:ServerResponse;

    public function new(request:IncomingMessage, response:ServerResponse) {
        incomingMessage = request;
        serverResponse = response;

        this.input = new NodeHttpSocketInput(request);
        this.output = new NodeHttpSocketOutput(response);
    }

    private function buildRequest():Request {
        request = new Request();
        request.host = incomingMessage.headers['host'];
        request.method = incomingMessage.method;
        request.path = StringTools.urlDecode(Url.parse(incomingMessage.url).pathname);
        request.ip = incomingMessage.socket.remoteAddress;
        request.context = this;

        // TODO: Implement Cookies
        /*for (keyValueIterator in exchange.getRequestCookies().entrySet()) {
            request.cookies.set(keyValueIterator.getKey(), keyValueIterator.getValue().getValue());
        }*/

        for (keyValueIterator in incomingMessage.headers.keyValueIterator()) {
            request.headers.set(keyValueIterator.key, keyValueIterator.value);
        }

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

            var acceptEncoding:String = request.header("Accept-Encoding", "");
            var encodings:Array<String> = acceptEncoding.split(",").map(value -> value.trim());

            if(encodings.contains("deflate"))
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
            }

            var statusCode:Int = response.statusCode ?? 200;
            serverResponse.writeHead(statusCode, generateHeader(response));

            beginWriteCalled = true;

            var responseInput:Input = response.toInput();

            if(response.encodingOptions is DeflateEncodingOptions) {
                responseInput = new ChunkedDeflateCompressInput(responseInput, cast response.encodingOptions);
            }

            try {
                output.writeInput(responseInput);
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

            output.flush();
        }

        if (response != null && response.after != null)
            response.after();
    }

    public function close():Void {
        try {
            output.close();
            serverResponse.end(null);
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
            output.writeString(header);
        } catch (e:Exception) {
            throw new haxe.Exception("Error writing response header: " + e.toString());
        }
    }

    public function writeInput(i:Input, ?bufsize:Int):Void {
        ensureReadyForWrite();
        output.writeInput(i, bufsize);
    }

    public function writeString(s:String, ?encoding:haxe.io.Encoding):Void {
        ensureReadyForWrite();
        output.writeString(s, encoding);
    }

    public function writeFullBytes(bytes:haxe.io.Bytes, pos:Int = 0, len:Int = -1):Void {
        ensureReadyForWrite();
        output.writeFullBytes(bytes, pos, len);
    }

    public function writeByte(c:Int):Void {
        ensureReadyForWrite();
        output.writeByte(c);
    }

    public function flush():Void {
        output.flush();
    }

    private inline function ensureReadyForWrite():Void {
        if (!beginWriteCalled) {
            beginWrite();
        }
    }

    private function generateHeader(response:Response = null):Dynamic {
        var staticResponse:Response = ResponseStatic.get();
        var finalResponse:Response = response == null ? staticResponse : response;

        var out:Dynamic = {};

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
            Reflect.setField(out, "Set-Cookie", cookieResponse);

        for (header in headers.keys()) {
            // Ignore content length header
            if(headers.exists("Content-Length") && header == "Content-Length")
                continue;

            Reflect.setField(out, header, headers.get(header));
        }

        if(contentLength != null)
            Reflect.setField(out, 'Content-Length', Std.string(contentLength));

        return out;
    }
}
#end