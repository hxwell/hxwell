package cases;

#if (jvm && security_socket_tests)
import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import hx.well.http.AbstractResponse;
import hx.well.http.CookieData;
import hx.well.http.HttpHandler;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseBuilder;
import hx.well.http.ResponseStatic;
import hx.well.http.StringResponse;
import hx.well.http.driver.socket.SocketDriver;
import hx.well.http.driver.socket.SocketDriverConfig;
import hx.well.http.driver.socket.SocketDriverContext;
import hx.well.route.Route;
import jvm.thread.VirtualThread;
import jvm.thread.VirtualThread.VirtualThreadExtern;
import sys.net.Host;
import sys.net.Socket;
import utest.Assert;

class TestJvmHttpSecurity extends utest.Test {
    var fixture:SecurityFixture;
    function setup() { fixture = new SecurityFixture(); }
    function teardown() { fixture.close(); }

    // Each accepted request, including keep-alive continuations, uses a real virtual thread.
    function exchange(raw:String, requests:Int = 1, halfClose:Bool = false):String {
        var listener = new Socket();
        listener.bind(new Host("127.0.0.1"), 0);
        listener.listen(4);
        listener.setTimeout(5);
        var driver = new SecuritySocketDriver();
        var acceptError:String = null;
        var acceptor = VirtualThread.create(() -> {
            try { driver.process(listener.accept()); }
            catch(e:Dynamic) { acceptError = Std.string(e); }
        });
        acceptor.start();
        var client = new Socket();
        client.setTimeout(5);
        var buffer = new BytesOutput();
        var failure:Dynamic = null;
        try {
            client.connect(new Host("127.0.0.1"), listener.host().port);
            client.output.writeString(raw);
            client.output.flush();
            if(halfClose) client.shutdown(false, true);
            try {
                while(buffer.length < 65536) buffer.writeByte(client.input.readByte());
                throw new Exception("Unexpectedly large HTTP response");
            } catch(e:haxe.io.Eof) {
                // Closed normally.
            } catch(e:Dynamic) {
                // Rejecting a request with unread attacker bytes can reset TCP.
                // Keep the already received response, but never accept a timeout.
                if(Std.string(e).toLowerCase().indexOf("reset") < 0) throw e;
            }
        } catch(e:Dynamic) { failure = e; }
        client.close();
        listener.close();
        acceptor.join(1000);
        var index = 0;
        while(index < driver.threads.length) {
            var thread = driver.threads[index++];
            thread.join(1000);
            if(thread.isAlive()) thread.interrupt();
            Assert.isFalse(thread.isAlive(), "HTTP worker did not finish");
        }
        driver.socket.close();
        Assert.isNull(acceptError);
        for(error in driver.errors) Assert.isNull(error);
        Assert.equals(requests, driver.threads.length, "Unexpected keep-alive request execution");
        if(failure != null) throw failure;
        return buffer.getBytes().toString();
    }

    function testSmuggledRequestNeverReachesEitherRoute() {
        var first = 0;
        var second = 0;
        Route.post("/allowed", req -> {
            first++;
            return (new StringResponse("first").header("Connection", "keep-alive") : AbstractResponse);
        });
        Route.get("/private", req -> { second++; return ("SECOND_REQUEST_EXECUTED" : AbstractResponse); });
        // Even a custom error page requesting persistence must not reuse malformed input.
        Route.status(400).handler(new hx.well.handler.DynamicHandler(req ->
            (new StringResponse("bad request", 400).header("Connection", "keep-alive") : AbstractResponse)));
        var payload = "ABCDGET /private HTTP/1.1\r\nHost: localhost\r\n\r\n";
        var chunked = StringTools.hex(payload.length).toLowerCase() + "\r\n" + payload + "\r\n0\r\n\r\n";
        var response = exchange("POST /allowed HTTP/1.1\r\nHost: localhost\r\nContent-Length: 4\r\nTransfer-Encoding: chunked\r\n\r\n" + chunked);
        Assert.isTrue(StringTools.startsWith(response, "HTTP/1.1 400 "));
        Assert.isTrue(response.indexOf("\r\nConnection: close\r\n") >= 0);
        Assert.equals(1, response.split("HTTP/1.1 ").length - 1);
        Assert.equals(0, first);
        Assert.equals(0, second);
    }

    function testMalformedFramingIsRejectedBeforeStreamingHandler() {
        var handled = 0;
        Route.post("/stream", req -> { handled++; return ("HANDLER_EXECUTED" : AbstractResponse); }).setStream(true);
        var cases = [
            {headers:"content-length:4\r\nTransfer-Encoding:chunked", status:400},
            {headers:"Content-Length: 4\r\ncOnTeNt-LeNgTh: 0", status:400},
            {headers:"Content-Length: 4\r\nContent-Length: 4", status:400},
            {headers:"Content-Length: 0x4", status:400},
            {headers:"Content-Length: +4", status:400},
            {headers:"Content-Length: 4junk", status:400},
            {headers:"Content-Length: 4294967300", status:400},
            {headers:"Content-Length : 4", status:400},
            {headers:"Content-Length:\u000b4", status:400},
            {headers:"Content-Length: 1048577", status:413},
            {headers:"Transfer-Encoding: chunked", status:501}
        ];
        for(test in cases) {
            var response = exchange("POST /stream HTTP/1.1\r\nHost: localhost\r\n" + test.headers + "\r\n\r\nDATA");
            Assert.isTrue(StringTools.startsWith(response, "HTTP/1.1 " + test.status + " "), test.headers + ": " + response);
            Assert.isTrue(response.indexOf("\r\nConnection: close\r\n") >= 0);
        }
        Assert.equals(0, handled);
    }

    function testBufferedAndStreamingKeepAlivePreserveNextRequest() {
        Route.post("/buffered", req ->
            (new StringResponse("body=" + req.bodyBytes.toString()).header("Connection", "keep-alive") : AbstractResponse));
        Route.post("/stream", req -> {
            var body = req.context.input.readAll().toString();
            return (new StringResponse("body=" + body).header("Connection", "keep-alive") : AbstractResponse);
        }).setStream(true);
        Route.post("/partial", req -> {
            var buffer = Bytes.alloc(2);
            req.context.input.readFullBytes(buffer, 0, 2);
            return (new StringResponse("body=" + buffer.toString()).header("Connection", "keep-alive") : AbstractResponse);
        }).setStream(true);
        Route.post("/bytes", req -> {
            var body = new StringBuf();
            try { while(true) body.addChar(req.context.input.readByte()); }
            catch(e:haxe.io.Eof) {}
            return (new StringResponse("body=" + body.toString()).header("Connection", "keep-alive") : AbstractResponse);
        }).setStream(true);
        Route.get("/next", req -> ("NEXT_REQUEST_OK" : AbstractResponse));
        for(path in ["/buffered", "/stream", "/partial", "/bytes"]) {
            var response = exchange("POST " + path + " HTTP/1.1\r\nhost:localhost\r\ncontent-length:\t4\r\n\r\nDATA"
                + "GET /next HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n", 2);
            Assert.equals(2, response.split("HTTP/1.1 200 ").length - 1, path);
            Assert.isTrue(response.indexOf("body=" + (path == "/partial" ? "DA" : "DATA") + "HTTP/1.1") >= 0, response);
            Assert.isTrue(StringTools.endsWith(response, "NEXT_REQUEST_OK"));
        }
    }

    function testShortBodyCannotRunHandlerOrKeepConnectionAlive() {
        var handled = false;
        Route.post("/body", req -> { handled = true; return ("HANDLER_EXECUTED" : AbstractResponse); });
        var response = exchange("POST /body HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\n\r\nabc", 1, true);
        Assert.isTrue(StringTools.startsWith(response, "HTTP/1.1 400 "));
        Assert.isFalse(handled);
    }

    function testResponseSplittingNeverAppearsOnTheWire() {
        Route.status(500).handler(new hx.well.handler.DynamicHandler(req -> (new StringResponse("invalid metadata", 500) : AbstractResponse)));
        Route.get("/redirect", req -> (ResponseBuilder.asRedirect(req.query("next")) : AbstractResponse));
        Route.get("/headers", req -> (new StringResponse("bad").withHeaders(["Location" => req.query("next")]) : AbstractResponse));
        Route.get("/static", req -> { ResponseStatic.header("Location", req.query("next")); return ("bad" : AbstractResponse); });
        Route.get("/status", req -> (new StringResponse("bad").status(200, req.query("next")) : AbstractResponse));
        Route.get("/cookie", req -> {
            var cookie = new CookieData("safe", "ok");
            var response = new StringResponse("bad").cookieFromData("safe", cookie);
            cookie.path = req.query("next");
            return (response : AbstractResponse);
        });
        for(path in ["/redirect", "/headers", "/static", "/status", "/cookie"]) {
            var response = exchange("GET " + path + "?next=%2Fsafe%0D%0ASet-Cookie%3Ainjected%3D1 HTTP/1.1\r\nHost: localhost\r\n\r\n");
            var headers = response.split("\r\n\r\n")[0];
            Assert.isTrue(StringTools.startsWith(response, "HTTP/1.1 500 "), path);
            Assert.isTrue(headers.indexOf("injected") == -1, headers);
            Assert.equals(1, response.split("HTTP/1.1 ").length - 1);
        }
        var valid = exchange("GET /redirect?next=%2Fsafe%3Fx%3D1 HTTP/1.1\r\nHost: localhost\r\n\r\n");
        Assert.isTrue(StringTools.startsWith(valid, "HTTP/1.1 302 "));
        Assert.isTrue(valid.indexOf("\r\nLocation: /safe?x=1\r\n") >= 0);
        var originalProbe = exchange("GET /redirect?next=%2Fsafe%0D%0ASet-Cookie%3Aaudit_marker%253D1 HTTP/1.1\r\nHost: localhost\r\n\r\n");
        Assert.isTrue(StringTools.startsWith(originalProbe, "HTTP/1.1 500 "));
        Assert.isTrue(originalProbe.split("\r\n\r\n")[0].indexOf("audit_marker") == -1);
    }
}

private class SecuritySocketDriver extends SocketDriver {
    public var threads:Array<java.lang.Thread> = [];
    public var errors:Array<String> = [];
    public function new() { super(new SocketDriverConfig()); }

    public override function process(socket:Socket):Void {
        var index = threads.length;
        errors[index] = null;
        var thread = VirtualThread.create(() -> {
            try {
                if(!VirtualThreadExtern.currentThread().isVirtual()) throw new Exception("Expected a virtual thread");
                socket.setTimeout(3);
                HttpHandler.process(new SocketDriverContext(socket, this));
                if(RequestStatic.request() != null || ResponseStatic.get() != null) throw new Exception("Request context leaked");
            } catch(e:Dynamic) {
                errors[index] = Std.string(e);
                socket.close();
            }
        });
        threads.push(thread);
        thread.start();
    }
}
#end
