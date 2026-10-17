package cases;

#if jvm
import haxe.Exception;
import haxe.ThreadLocal;
import haxe.io.Bytes;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.facades.Auth;
import hx.well.facades.Cache;
import hx.well.http.AbstractResponse;
import hx.well.http.HttpHandler;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseBuilder;
import hx.well.http.ResponseStatic;
import hx.well.http.StringResponse;
import hx.well.http.driver.socket.SocketDriverContext;
import hx.well.internal.SecureToken;
import hx.well.middleware.SessionMiddleware;
import hx.well.route.Route;
import hx.well.session.SessionDataType;
import hx.well.template.TemplateData;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import jvm.thread.VirtualThread;
import jvm.thread.VirtualThread.VirtualThreadExtern;
import utest.Assert;

class TestJvmSecurity extends utest.Test {
    var fixture:SecurityFixture;

    function setup() { fixture = new SecurityFixture(); }
    function teardown() { fixture.close(); }

    // Assertions run on the test runner thread; worker failures are handed back.
    static function parallel(count:Int, work:Int->Void):Void {
        var start = new CountDownLatch(1);
        var done = new CountDownLatch(count);
        var errors:Array<String> = [for(_ in 0...count) null];
        var threads:Array<java.lang.Thread> = [];
        for(i in 0...count) {
            var index = i;
            var thread = VirtualThread.create(() -> {
                try {
                    if(!VirtualThreadExtern.currentThread().isVirtual())
                        throw new Exception("Expected a real JVM virtual thread");
                    if(!start.await(5, TimeUnit.SECONDS))
                        throw new Exception("Start barrier timed out");
                    work(index);
                } catch(e:Dynamic) {
                    errors[index] = Std.string(e) + haxe.CallStack.toString(haxe.CallStack.exceptionStack());
                }
                RequestStatic.reset();
                ResponseStatic.clear();
                done.countDown();
            });
            threads.push(thread);
            thread.start();
        }
        start.countDown();
        var completed = done.await(30, TimeUnit.SECONDS);
        if(!completed)
            for(thread in threads) thread.interrupt();
        for(thread in threads) thread.join(1000);
        Assert.isTrue(completed, "Virtual thread workers must finish within 30s");
        for(error in errors) Assert.isNull(error);
    }

    function testConcurrentTemplatesNeverShareRenderState() {
        var source = [for(_ in 0...200) "::secret::|"].join("");
        TemplateData.data.set("security-concurrent", source);
        ResponseBuilder.asTemplate("security-concurrent", {secret:"warmup"});
        parallel(32, index -> {
            var own = "private-user-" + index + "!";
            var expected = [for(_ in 0...200) own + "|"].join("");
            for(_ in 0...50) {
                var actual = ResponseBuilder.asTemplate("security-concurrent", {secret:own}).toString();
                if(actual != expected)
                    throw new Exception("Render leaked or corrupted another request's context");
            }
        });
        TemplateData.data.remove("security-concurrent");
    }

    function testThreadLocalIsolationAndRemoval() {
        var local = new ThreadLocal<String>();
        local.set("parent");
        parallel(64, index -> {
            if(local.get() != null) throw new Exception("Inherited another thread's value");
            local.set("worker-" + index);
            for(_ in 0...32) {
                java.lang.Thread.sleep(1);
                if(local.get() != "worker-" + index) throw new Exception("Thread-local isolation failed");
            }
            local.remove();
            if(local.get() != null) throw new Exception("Thread-local value was retained");
        });
        Assert.equals("parent", local.get());
        local.remove();
        Assert.isNull(local.get());
        var callbacks = 0;
        var initialized = new ThreadLocal<String>(() -> "initial", value -> { callbacks++; throw new Exception("cleanup failure"); });
        Assert.equals("initial", initialized.get());
        Assert.raises(() -> initialized.remove(), Exception);
        initialized.set(null); // No second cleanup callback, even after the first one threw.
        Assert.equals(1, callbacks);
    }

    function testRequestStateReleasedUnderVirtualThreadLoad() {
        Route.get("/scope", req -> {
            if(RequestStatic.request() != req) throw new Exception("Wrong current request");
            return ("ok" : AbstractResponse);
        });
        parallel(32, index -> {
            for(_ in 0...64) {
                var request = SecurityFixture.request("/scope");
                request.bodyBytes = Bytes.alloc(65536);
                var context = new FakeDriverContext(request);
                HttpHandler.process(context);
                if(RequestStatic.request() != null || ResponseStatic.get() != null)
                    throw new Exception("Request context retained after completion");
                if(!context.closed || context.written[0].toString() != "ok")
                    throw new Exception("Response did not complete");
            }
        });
    }

    function testCleanupOnErrorsAbortAndAsync() {
        Route.get("/abort", req -> { ResponseStatic.abort(403); return null; });
        Route.get("/async", req -> (ResponseBuilder.asAsync() : AbstractResponse));
        Route.get("/normal", req -> ("ok" : AbstractResponse));
        // Warm up the shared error-template classes before parallel use.
        HttpHandler.process(new FakeDriverContext(SecurityFixture.request("/abort")));
        parallel(8, index -> {
            for(path in ["/abort", "/async", "/normal", "/missing"]) {
                var context = new FakeDriverContext(SecurityFixture.request(path));
                HttpHandler.process(context);
                if(RequestStatic.request() != null || ResponseStatic.get() != null)
                    throw new Exception("Context leaked for " + path);
                if(path == "/async" && context.closed)
                    throw new Exception("Async context closed prematurely");
            }
            var broken = new FakeDriverContext(SecurityFixture.request("/normal"));
            broken.failBuild = true;
            HttpHandler.process(broken);
            if(RequestStatic.request() != null || ResponseStatic.get() != null)
                throw new Exception("Context leaked after request parse failure");
            var closeFailed = false;
            try {
                HttpHandler.process(new FailingCloseContext(SecurityFixture.request("/normal")));
            } catch(e:Dynamic) { closeFailed = true; }
            if(!closeFailed || RequestStatic.request() != null || ResponseStatic.get() != null)
                throw new Exception("Context leaked after close failure");
        });
    }

    function testAsyncDriverKeepsOnlyItsOwnResponseHeaders() {
        var socket = new sys.net.Socket();
        var context = new SocketDriverContext(socket, null);
        ResponseStatic.reset();
        ResponseStatic.header("X-Owner", "original-request");
        ResponseStatic.cookie("owner", "original-request");
        context.writeResponse(ResponseBuilder.asAsync());
        ResponseStatic.clear();
        parallel(1, index -> {
            ResponseStatic.reset();
            ResponseStatic.header("X-Owner", "unrelated-request");
            var header = @:privateAccess context.generateHeader(new StringResponse("later"));
            if(header.indexOf("X-Owner: original-request") < 0 || header.indexOf("unrelated-request") >= 0)
                throw new Exception("Deferred response lost its request headers");
            if(header.indexOf("owner=original-request") < 0)
                throw new Exception("Deferred response lost its request cookies");
        });
        socket.close();
    }

    function testLogoutRaceOnRealVirtualThreads() {
        for(modified in [true, false]) {
            var old = TestSecurity.authenticatedCookie();
            var loaded = new CountDownLatch(1);
            var revoked = new CountDownLatch(1);
            // Warm up auth before worker execution, so initialization cannot mask a race.
            var warmup = new Auth(SecurityFixture.request(), "default");
            parallel(2, index -> {
                if(index == 0) {
                    var earlier = TestSecurity.loadSession(old.cookie);
                    if(earlier.session.getWithEnum(SessionDataType.AUTH_ID("default")) != "test-user")
                        throw new Exception("Race fixture did not load authenticated state");
                    if(modified) earlier.session.put("ordinary-update", true);
                    earlier.session.needsRefresh = true;
                    loaded.countDown();
                    if(!revoked.await(10, TimeUnit.SECONDS)) throw new Exception("Logout timed out");
                    new SessionMiddleware().dispose();
                } else {
                    if(!loaded.await(10, TimeUnit.SECONDS)) throw new Exception("Session load timed out");
                    var logout = TestSecurity.loadSession(old.cookie);
                    new Auth(logout, "default").logout();
                    new SessionMiddleware().dispose();
                    revoked.countDown();
                }
            });
            Assert.isFalse(Cache.store(FileSystemSessionCacheStore).has("session." + old.key));
            var replay = TestSecurity.loadSession(old.cookie);
            Assert.isNull(replay.session.getWithEnum(SessionDataType.AUTH_ID("default")));
            Assert.notEquals(old.key, replay.session.sessionKey);
        }
    }

    function testConcurrentSecureTokens() {
        var tokens:Array<Array<String>> = [for(_ in 0...32) null];
        parallel(32, index -> {
            tokens[index] = [for(_ in 0...64) SecureToken.generate(40)];
        });
        var seen:Map<String, Bool> = new Map();
        var duplicates = 0;
        var malformed = 0;
        for(batch in tokens) for(token in batch) {
            if(seen.exists(token)) duplicates++;
            if(!~/^[A-Za-z0-9_-]{40}$/.match(token)) malformed++;
            seen.set(token, true);
        }
        Assert.equals(0, duplicates);
        Assert.equals(0, malformed);
    }

    function testRevocationWinsAgainstConcurrentStoreInstances() {
        var old = TestSecurity.authenticatedCookie();
        var key = "session." + old.key;
        var stale:Map<String, Dynamic> = Cache.store(FileSystemSessionCacheStore).get(key);
        parallel(16, index -> {
            var store = new FileSystemSessionCacheStore();
            for(i in 0...32) {
                store.put(key, stale, 3600);
                if(index == 0 && i == 8) store.forget(key);
            }
        });
        var reader = new FileSystemSessionCacheStore();
        Assert.isFalse(reader.has(key));
        Assert.isNull(reader.get(key));
    }

    #if security_socket_tests
    function testRealHttpRequestsOnVirtualThreads() {
        TemplateData.data.set("security-http", "private-user-::id::");
        ResponseBuilder.asTemplate("security-http", {id:"warmup"});
        Route.get("/render/{id}", request -> {
            if(!VirtualThreadExtern.currentThread().isVirtual()) throw new Exception("HTTP handler is not virtual");
            return (ResponseBuilder.asTemplate("security-http", {id:request.route("id")}) : AbstractResponse);
        }).middleware(SessionMiddleware).middleware(hx.well.middleware.CsrfMiddleware);
        Route.get("/async/{id}", request -> {
            ResponseStatic.header("X-Owner", request.route("id"));
            return (ResponseBuilder.asAsync() : AbstractResponse);
        });
        sys.FileSystem.createDirectory(fixture.root + "/public/.private");
        sys.io.File.saveContent(fixture.root + "/public/.private/config.txt", "secret");
        var listener = new sys.net.Socket();
        listener.bind(new sys.net.Host("127.0.0.1"), 0);
        listener.listen(16);
        listener.setTimeout(10);
        var port = listener.host().port;
        var accepted = new CountDownLatch(1);
        var served = new CountDownLatch(9);
        var serverError:String = null;
        var errors:Array<String> = [for(_ in 0...9) null];
        var server = VirtualThread.create(() -> {
            try {
                for(i in 0...9) {
                    var index = i;
                    var socket = listener.accept();
                    socket.setTimeout(5);
                    VirtualThread.create(() -> {
                        try {
                            var context = new SocketDriverContext(socket, null);
                            HttpHandler.process(context);
                            if(RequestStatic.request() != null || ResponseStatic.get() != null)
                                throw new Exception("Live HTTP request retained its context");
                            var request = @:privateAccess context.request;
                            if(request.existsAttribute("is_async_response"))
                                context.writeResponse(new StringResponse("async-user-" + request.route("id")));
                        } catch(e:Dynamic) { errors[index] = Std.string(e); socket.close(); }
                        served.countDown();
                    }).start();
                }
            } catch(e:Dynamic) { serverError = Std.string(e); }
            accepted.countDown();
        });
        server.start();
        parallel(9, index -> {
            var path = index == 8 ? "/.private/config.txt" : (index % 2 == 0 ? "/render/" : "/async/") + index;
            var client = new sys.net.Socket();
            client.setTimeout(5);
            client.connect(new sys.net.Host("127.0.0.1"), port);
            client.output.writeString("GET " + path + " HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n");
            client.output.flush();
            var response = client.input.readAll().toString();
            client.close();
            if(index == 8) {
                if(!StringTools.startsWith(response, "HTTP/1.1 403")) throw new Exception("Hidden file was not denied over HTTP");
            } else {
                if(!StringTools.startsWith(response, "HTTP/1.1 200")) throw new Exception("HTTP request failed: " + response);
                var body = response.substr(response.indexOf("\r\n\r\n") + 4);
                var expected = (index % 2 == 0 ? "private-user-" : "async-user-") + index;
                if(body != expected) throw new Exception("Wrong HTTP response body: " + body);
                if(index % 2 == 0 && response.indexOf("Set-Cookie: XSRF-TOKEN=") < 0)
                    throw new Exception("CSRF cookie was not sent");
                if(index % 2 != 0 && response.indexOf("X-Owner: " + index) < 0)
                    throw new Exception("Deferred HTTP response lost its own headers");
            }
        });
        listener.close();
        Assert.isTrue(accepted.await(5, TimeUnit.SECONDS));
        Assert.isTrue(served.await(5, TimeUnit.SECONDS));
        server.join(1000);
        Assert.isNull(serverError);
        for(error in errors) Assert.isNull(error);
        TemplateData.data.remove("security-http");
    }
    #end
}

private class FailingCloseContext extends FakeDriverContext {
    public override function close():Void {
        throw new Exception("expected close failure");
    }
}
#end
