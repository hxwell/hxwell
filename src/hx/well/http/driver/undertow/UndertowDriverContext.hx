package hx.well.http.driver.undertow;

#if java

import hx.well.http.driver.IDriverContext;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.http.driver.socket.SocketRequestParser;
import haxe.io.Input;
import hx.well.http.driver.undertow.UndertowExtern.HttpServerExchangeExtern;
import hx.well.http.driver.undertow.UndertowExtern.HttpStringExtern;
import hx.well.http.driver.undertow.UndertowExtern.ExternCookieImpl;
import haxe.io.Encoding;
import haxe.Exception;
import haxe.CallStack;
import haxe.io.Output;
using hx.well.tools.MapTools;

@:access(hx.well.http.Request)
class UndertowDriverContext implements IDriverContext {
    var exchange:HttpServerExchangeExtern;
    var socket:UndertowSocket;
    var request:Request;

    var beginWriteCalled:Bool = false;

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

    public function new(exchange:HttpServerExchangeExtern) {
        this.exchange = exchange;
        this.socket = new UndertowSocket(exchange);
        this.input = socket.input;
        this.output = socket.output;
    }

    private function buildRequest():Request {
        request = new Request();
        request.host = exchange.getHostName();
        request.method = exchange.getRequestMethod().toString();
        request.path = exchange.getRequestPath();
        request.ip = exchange.getSourceAddress().getAddress().getHostAddress();
        request.context = this;

        for (keyValueIterator in exchange.getRequestCookies().entrySet()) {
            request.cookies.set(keyValueIterator.getKey(), keyValueIterator.getValue().getValue());
        }

        for (header in exchange.getRequestHeaders()) {
            request.headers.set(header.getHeaderName().toString(), header.getFirst());
        }

        return request;
    }

    private function parseBody():Void {
        SocketRequestParser.parseBody(request, socket.input);
    }

    public function writeInput(i:Input, ?bufsize:Int):Void {
        ensureReadyForWrite();
        socket.output.writeInput(i, bufsize);
    }

    public function writeString(s:String, ?encoding:Encoding) {
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

    public function writeBytes(s:haxe.io.Bytes, pos:Int = 0, len:Int = -1):Int {
        ensureReadyForWrite();
        return socket.output.writeBytes(s, pos, len);
    }

    public function writeResponse(response:Response):Void {
        if(beginWriteCalled)
            throw new Exception("beginWrite() already called, cannot write response now.");

        if (response is AsyncResponse)
            return;

        if (response != null) {
            response.concat(ResponseStatic.get());
            // All cookies
            setCookies(response.cookies);

            var contentLength = response.contentLength;
            if(contentLength != null) {
                response.headers.set("Content-Length", haxe.Int64.toStr(contentLength));
            }

            // All headers
            setHeaders(response.headers);

            exchange.setStatusCode(response.statusCode ?? 200);

            var responseInput:Input = response.toInput();

            try  {
                socket.output.writeInput(responseInput);
            } catch (e:Exception) {
                trace(e, CallStack.toString(e.stack)); // TODO: Log error
            }

            try {
                responseInput.close();
            } catch (e) {
                trace(e);
            }

            flush();
        }

        if (response != null && response.after != null)
            response.after();
    }

    public function close():Void {
        try {
            socket.close();
        } catch (e:Dynamic) {
            // Socket already closed, ignore.
        }
    }

    public function beginWrite():Void {
        if (beginWriteCalled)
            return;

        beginWriteCalled = true;

        var staticResponse = ResponseStatic.get();
        setCookies(staticResponse.cookies);
        setHeaders(staticResponse.headers);
        exchange.setStatusCode(staticResponse.statusCode ?? 200);
    }

    public function flush():Void {
        socket.output.flush();
    }

    private inline function ensureReadyForWrite():Void {
        if (!beginWriteCalled) {
            beginWrite();
        }
    }

    private function setCookies(cookies:Map<String, CookieData>):Void {
        var responseCookies = exchange.getResponseCookies();
        for (cookie in cookies) {
            var externCookie = new ExternCookieImpl(cookie.key, cookie.value);
            externCookie.setValue(cookie.value);
            externCookie.setSecure(cookie.secure);
            externCookie.setHttpOnly(cookie.httpOnly);
            externCookie.setSameSite(cookie.sameSite != null);
            externCookie.setSameSiteMode(cookie.sameSite);
            externCookie.setPath(cookie.path);
            externCookie.setDomain(cookie.domain);
            externCookie.setMaxAge(cookie.maxAge);
            responseCookies.put(cookie.key, externCookie);
        }
    }

    private function setHeaders(headers:Map<String, String>):Void {
        var responseHeaders = exchange.getResponseHeaders();
        for (keyValueIterator in headers.keyValueIterator()) {
            responseHeaders.add(new HttpStringExtern(keyValueIterator.key), keyValueIterator.value);
        }
    }
}
#end