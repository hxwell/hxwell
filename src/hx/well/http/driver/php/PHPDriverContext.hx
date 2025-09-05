package hx.well.http.driver.php;
import haxe.io.Input;
import hx.well.http.driver.IDriverContext;
import hx.well.http.Request;
import hx.well.http.Response;
import php.Global;
import sys.io.FileInput;
import sys.io.FileOutput;
import haxe.io.Output;
import php.NativeAssocArray;
import haxe.Exception;
import hx.well.http.driver.socket.SocketRequestParser;
using hx.well.tools.MapTools;

class PHPDriverContext implements IDriverContext {
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

    private var request:Request;
    private var beginWriteCalled:Bool = false;
    private var needHeader:Bool = true;

    public function new() {
        var outStream = Global.fopen('php://output', 'w');
        output = @:privateAccess new FileOutput(outStream);
        var inStream = Global.fopen('php://input', 'r');
        input = @:privateAccess new FileInput(inStream);
    }

    private function buildRequest():Request {
        request = new Request();
        request.host = Global.getenv("HTTP_HOST") ?? "";
        request.method = Global.getenv("REQUEST_METHOD") ?? "GET";
        request.path = Global.getenv("REQUEST_URI") ?? "/";
        request.ip = Global.getenv("REMOTE_ADDR") ?? "";
        for(keyValueIterator in Global.getallheaders().keyValueIterator()) {
            request.headers.set(keyValueIterator.key.toString(), keyValueIterator.value);
        }

        var cookies:NativeAssocArray<Dynamic> = untyped php.Syntax.code("$_COOKIE");
        for(keyValueIterator in cookies.keyValueIterator()) {
            request.cookies.set(keyValueIterator.key, keyValueIterator.value);
        }
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
            generateHeader(response);
            needHeader = false;

            var responseInput:Input = response.toInput();
            writeInput(responseInput);

            try {
                responseInput.close();
            } catch (e) {
                trace(e); // TODO: Log error
            }

            output.flush();
        }

        if (response != null && response.after != null)
            response.after();
    }

    public function close():Void {
        try {
            output.close();
        } catch (e:Dynamic) {
            // Socket zaten kapalı olabilir, görmezden gel.
        }
    }

    public function beginWrite():Void {
        if (beginWriteCalled)
            return;

        beginWriteCalled = true;

        if(needHeader)
            generateHeader();
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

    private function generateHeader(response:Response = null): Void {
        var staticResponse:Response = ResponseStatic.get();
        var finalResponse:Response = response == null ? staticResponse : response;

        var statusCode:Int = (finalResponse.statusCode == null ? 200 : finalResponse.statusCode);
        Global.http_response_code(statusCode);

        var headers:Map<String, String> = response == null ? staticResponse.headers : response.headers.concat(staticResponse.headers, false);
        var cookies:Map<String, CookieData> = response == null ? staticResponse.cookies : response.cookies.concat(staticResponse.cookies, false);
        var contentLength = response == null ? staticResponse.contentLength : (response.contentLength ?? staticResponse.contentLength);

        for(key in cookies.keys())
        {
            var cookieData = cookies.get(key);
            Global.setcookie(cookieData.key, cookieData.value, cookieData.maxAge, cookieData.path, cookieData.domain, cookieData.secure, cookieData.httpOnly);
        }

        for (header in headers.keys()) {
            // Ignore content length header
            if(headers.exists("Content-Length") && header == "Content-Length")
                continue;

            Global.header(header + ": " + headers.get(header));

        }

        if(contentLength != null)
            Global.header('Content-Length: ${contentLength}');
    }
}