package hx.well.http;
import haxe.io.Input;
import haxe.io.BytesInput;
import haxe.Int64;
import haxe.io.Bytes;
import hx.well.session.ISession;

@:allow(hx.well.WebServer)
class Response {
    public var statusCode:Null<Int>;
    private var statusMessage: String = null;
    private var headers: Map<String, String> = new Map();
    private var cookies: Map<String, String> = new Map();
    private var after:Void->Void;
    public var contentLength:Null<Int64> = null;

    public function new(statusCode:Null<Int> = null) {
        this.statusCode = statusCode;
    }

    public function withHeaders(headers:Map<String, String>):Response {
        for(keyValueIterator in headers.keyValueIterator()) {
            this.headers.set(keyValueIterator.key, keyValueIterator.value);
        }

        return this;
    }

    public function header(key:String, value:String):Response {
        headers.set(key, value);
        return this;
    }

    public function cookie(key:String, value:String):Response {
        cookies.set(key, value);
        return this;
    }

    public function status(statusCode:Int, status:String = null):Response {
        this.statusCode = statusCode;
        this.statusMessage = status;
        return this;
    }

    public function onAfter(after:Void->Void):Response {
        this.after = after;
        return this;
    }

    public function generateHeader(): String {
        var statusCode:Int = (this.statusCode == null ? 200 : this.statusCode);
        var statusMessage:String = this.statusMessage == null ? ResponseStatic.getStatusMessage(statusCode) : this.statusMessage;

        var response: String = "HTTP/1.1 " + statusCode + " " + statusMessage + "\r\n";

        var headers = headers.copy();
        var responseStatic:ResponseStatic = ResponseStatic.get();
        for(keyValueIterator in responseStatic.headers.keyValueIterator())
        {
            if(!headers.exists(keyValueIterator.key))
                headers.set(keyValueIterator.key, keyValueIterator.value);
        }

        var cookies = cookies.copy();
        for(keyValueIterator in responseStatic.cookies.keyValueIterator())
        {
            if(!cookies.exists(keyValueIterator.key))
                cookies.set(keyValueIterator.key, keyValueIterator.value);
        }

        var cookieResponse:String = "";
        for(key in cookies.keys())
        {
            var data = cookies.get(key);
            cookieResponse += '${key}=${data};';
        }
        if(cookieResponse != "")
            headers.set("Set-Cookie", cookieResponse);

        for (header in headers.keys()) {
            // Ignore content length header
            if(headers.exists("Content-Length") && header == "Content-Length")
                continue;

            response += header + ": " + headers.get(header) + "\r\n";
        }

        if(contentLength != null)
            response += 'Content-Length: ${contentLength}\r\n';
        response += "\r\n";
        return response;
    }

    public function toString():String {
        return "";
    }

    public function toBytes():Bytes {
        var bytes = Bytes.ofString(toString());
        contentLength = bytes.length;
        return bytes;
    }

    public function toInput():Input {
        return new BytesInput(toBytes());
    }

    public function dispose():Void
    {

    }
}
