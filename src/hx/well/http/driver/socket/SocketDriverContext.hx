package hx.well.http.driver.socket;
import sys.net.Socket;
import haxe.io.Input;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.driver.IDriverContext;
import haxe.Exception;
using hx.well.tools.MapTools;

class SocketDriverContext implements IDriverContext {
    private var socket:Socket;
    private var request:Request;
    private var beginWriteCalled:Bool = false;

    public function new(socket:Socket) {
        this.socket = socket;
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

        if (response is ManualResponse)
            return;

        if (response != null) {
            socket.output.writeString(generateHeader(response));

            var responseInput:Input = response.toInput();
            socket.output.writeInput(responseInput);

            try {
                responseInput.close();
            } catch (e) {
                trace(e); // TODO: Log error
            }

            socket.output.flush();
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

        if(finalResponse.contentLength != null)
            responseBuffer.add('Content-Length: ${finalResponse.contentLength}\r\n');
        responseBuffer.add("\r\n");
        return responseBuffer.toString();
    }
}