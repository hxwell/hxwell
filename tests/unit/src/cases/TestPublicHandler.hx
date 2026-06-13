package cases;

import utest.Assert;
import hx.well.handler.PublicHandler;
import hx.well.http.Request;
import hx.well.exception.AbortException;

class TestPublicHandler extends utest.Test {
    function request(path:String):Request {
        var request = new Request();
        request.method = "GET";
        request.path = path;
        return request;
    }

    function statusFor(path:String):Int {
        try {
            new PublicHandler().execute(request(path));
            return 200;
        } catch (e:AbortException) {
            return @:privateAccess e.statusCode;
        }
    }

    function testServesExistingFile() {
        Assert.equals(200, statusFor("/index.html"));
    }

    function testMissingFileIsNotFound() {
        Assert.equals(404, statusFor("/no-such-file.html"));
    }

    function testTraversalCannotEscapePublicRoot() {
        Assert.notEquals(200, statusFor("/../secrets.txt"));
        Assert.equals(403, statusFor("/../../etc/passwd"));
    }

    function testEncodedTraversalIsForbidden() {
        Assert.equals(403, statusFor("/%2e%2e/secrets.txt"));
    }

    function testDotfilesAreForbidden() {
        Assert.equals(403, statusFor("/.hidden"));
        Assert.equals(403, statusFor("/.env"));
    }
}
