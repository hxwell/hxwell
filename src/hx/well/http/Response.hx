package hx.well.http;
import haxe.io.Input;
import haxe.io.BytesInput;
import haxe.Int64;
import haxe.io.Bytes;
using hx.well.tools.MapTools;

@:allow(hx.well.http.HttpHandler)
@:allow(hx.well.http.driver.IDriverContext)
@:allow(hx.well.http.ResponseStatic)
class Response {
    public var statusCode:Null<Int>;
    private var statusMessage: String = null;
    private var headers: Map<String, String> = new Map();
    private var cookies: Map<String, CookieData> = new Map();
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

    public function cookie(key:String, value:String):Null<CookieBuilder<Response>> {
        if(value == null)
        {
            cookies.remove(key);
            return null;
        }
        else
        {
            var cookieData:CookieData = new CookieData(key, value);
            cookies.set(key, cookieData);
            return new CookieBuilder<Response>(this, cookieData);
        }
    }

    public function cookieFromData(key:String, value:CookieData):Response {
        if(value == null)
        {
            cookies.remove(key);
            return this;
        }
        else
        {
            cookies.set(key, value);
            return this;
        }
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

    public function asStatic():Void {
        ResponseStatic.set(this);
    }

    public function dispose():Void
    {

    }
}
