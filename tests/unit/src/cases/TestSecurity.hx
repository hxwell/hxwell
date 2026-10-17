package cases;

import haxe.Exception;
import haxe.io.BytesBuffer;
import hx.well.cache.FileSystemCacheStore;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.exception.AbortException;
import hx.well.facades.Auth;
import hx.well.facades.Cache;
import hx.well.facades.Config;
import hx.well.handler.PublicHandler;
import hx.well.http.CookieData;
import hx.well.http.Request;
import hx.well.http.RequestStatic;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.internal.SecureToken;
import hx.well.middleware.CsrfMiddleware;
import hx.well.middleware.SessionMiddleware;
import hx.well.session.Session;
import hx.well.session.SessionDataType;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;

class TestSecurity extends utest.Test {
    var fixture:SecurityFixture;

    function setup() { fixture = new SecurityFixture(); }
    function teardown() { fixture.close(); }

    public static function authenticatedCookie():{key:String, cookie:String} {
        var seed = new Session();
        seed.sessionKey = SessionMiddleware.generateSessionKey();
        seed.putWithEnum(SessionDataType.AUTH_ID("default"), "test-user");
        seed.save();
        return {key:seed.sessionKey, cookie:new CookieData(SessionMiddleware.sessionCookieKey(), seed.sessionKey, true).value};
    }

    public static function loadSession(cookie:String):Request {
        var request = SecurityFixture.request();
        @:privateAccess request.cookies.set(SessionMiddleware.sessionCookieKey(), cookie);
        RequestStatic.set(request);
        ResponseStatic.reset();
        new SessionMiddleware().handle(request, req -> null);
        return request;
    }

    function testLogoutCannotBeUndoneByOlderSaveOrTouch() {
        for(modified in [true, false]) {
            var old = authenticatedCookie();
            var earlier = loadSession(old.cookie);
            Assert.equals("test-user", earlier.session.getWithEnum(SessionDataType.AUTH_ID("default")));
            if(modified) earlier.session.put("ordinary-update", true);
            earlier.session.needsRefresh = true;

            var logout = loadSession(old.cookie);
            new Auth(logout, "default").logout();
            new SessionMiddleware().dispose();
            Assert.isFalse(Cache.store(FileSystemSessionCacheStore).has("session." + old.key));

            RequestStatic.set(earlier);
            new SessionMiddleware().dispose();
            Assert.isFalse(Cache.store(FileSystemSessionCacheStore).has("session." + old.key));
            var replay = loadSession(old.cookie);
            Assert.isNull(replay.session.getWithEnum(SessionDataType.AUTH_ID("default")));
            Assert.notEquals(old.key, replay.session.sessionKey);
        }
    }

    function testRevocationSurvivesNewStoreInstances() {
        var old = authenticatedCookie();
        var key = "session." + old.key;
        var writer = new FileSystemSessionCacheStore();
        var stale:Map<String, Dynamic> = writer.get(key);
        new FileSystemSessionCacheStore().forget(key);
        writer.put(key, stale, 3600);
        Assert.isFalse(writer.touch(key, 3600));
        var reader = new FileSystemSessionCacheStore();
        Assert.isFalse(reader.has(key));
        Assert.isNull(reader.get(key));
    }

    function testRegenerationPreservesAuthOnlyOnNewSession() {
        var old = authenticatedCookie();
        var request = loadSession(old.cookie);
        request.session.regenerate();
        var newKey = request.session.sessionKey;
        new SessionMiddleware().dispose();
        var newCookie = new CookieData(SessionMiddleware.sessionCookieKey(), newKey, true).value;
        Assert.notEquals(old.key, newKey);
        Assert.equals("test-user", loadSession(newCookie).session.getWithEnum(SessionDataType.AUTH_ID("default")));
        Assert.isNull(loadSession(old.cookie).session.getWithEnum(SessionDataType.AUTH_ID("default")));
    }

    function publicStatus(path:String):Int {
        try {
            var response:Response = new PublicHandler().execute(SecurityFixture.request(path));
            response.toInput().close();
            return 200;
        } catch(e:AbortException) {
            return @:privateAccess e.statusCode;
        }
    }

    function testPublicRootRejectsHiddenDirectories() {
        FileSystem.createDirectory(fixture.root + "/public/.private");
        File.saveContent(fixture.root + "/public/.private/config.txt", "secret");
        Assert.equals(403, publicStatus("/.private/config.txt"));
        Assert.equals(403, publicStatus("/.private/../.private/config.txt"));
        Assert.equals(403, publicStatus("/%2eprivate/config.txt"));
        Assert.equals(404, publicStatus("/missing.txt"));
    }

    function testPublicRootResolvesSymlinksIncludingDirectoryIndex() {
        if(Sys.systemName() == "Windows") { Assert.pass(); return; }
        var root = fixture.root;
        File.saveContent(root + "/outside.txt", "secret");
        File.saveContent(root + "/public/visible.txt", "public");
        FileSystem.createDirectory(root + "/public/.private");
        File.saveContent(root + "/public/.private/config.txt", "secret");
        FileSystem.createDirectory(root + "/public/dir");
        fixture.symlink("../outside.txt", root + "/public/escape.txt");
        fixture.symlink("visible.txt", root + "/public/safe.txt");
        fixture.symlink(".private/config.txt", root + "/public/hidden.txt");
        fixture.symlink("../../outside.txt", root + "/public/dir/index.html");
        Assert.equals(403, publicStatus("/escape.txt"));
        Assert.equals(403, publicStatus("/hidden.txt"));
        Assert.equals(403, publicStatus("/dir/"));
        Assert.equals(200, publicStatus("/visible.txt"));
        Assert.equals(200, publicStatus("/safe.txt"));
    }

    function testCsrfStillRejectsMissingAndIncorrectTokens() {
        var request = SecurityFixture.request("/", "POST");
        request.session = new Session();
        var middleware = new CsrfMiddleware();
        Assert.raises(() -> middleware.handle(request, req -> null), AbortException);
        var token:String = request.session.get(CsrfMiddleware.TOKEN_KEY);
        Assert.equals(40, token.length);
        @:privateAccess request.headers.set("X-CSRF-TOKEN", "invalid");
        Assert.raises(() -> middleware.handle(request, req -> null), AbortException);
        @:privateAccess request.headers.set("X-CSRF-TOKEN", token);
        var called = false;
        middleware.handle(request, req -> { called = true; return null; });
        Assert.isTrue(called);
    }

    function testSecureTokenFormatAndLength() {
        Assert.raises(() -> SecureToken.generate(0), Exception);
        Assert.raises(() -> SecureToken.generate(-1), Exception);
        Assert.isTrue(~/^[A-Za-z0-9_-]{32}$/.match(SessionMiddleware.generateSessionKey()));
        Assert.isTrue(~/^[A-Za-z0-9_-]{40}$/.match(new CsrfMiddleware().generateToken()));
    }

    function testFileCachePrecisionAndLegacyCompatibility() {
        var store = new FileSystemCacheStore();
        store.put("precise", "value", 60);
        var entry = @:privateAccess store.getRaw("precise");
        Assert.floatEquals(Sys.time() + 60, entry.expireAt, 1.0);
        Assert.isTrue(store.touch("precise", 120));
        Assert.floatEquals(Sys.time() + 120, (@:privateAccess store.getRaw("precise")).expireAt, 1.0);
        Assert.equals("value", store.get("precise"));

        var legacy = new BytesBuffer();
        legacy.addString(FileSystemCacheStore.header);
        legacy.addByte(0);
        legacy.addFloat(Sys.time() + 3600);
        legacy.addInt32(6);
        legacy.addString("legacy");
        var data = haxe.Serializer.run("old value");
        legacy.addInt32(data.length);
        legacy.addString(data);
        File.saveBytes(Config.get("http.cache_path") + "/" + store.cacheKey("legacy"), legacy.getBytes());
        Assert.equals("old value", store.get("legacy"));
        Assert.isTrue(store.touch("legacy", 7200));
        Assert.equals("old value", store.get("legacy"));
    }
}
