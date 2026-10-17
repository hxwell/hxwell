package cases;

import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hx.well.exception.AbortException;
import hx.well.http.CookieData;
import hx.well.http.RequestParser;
import hx.well.http.RequestStatic;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.http.driver.socket.SocketRequestParser;
import utest.Assert;

class TestHttpSecurity extends utest.Test {
    var fixture:SecurityFixture;
    function setup() { fixture = new SecurityFixture(); }
    function teardown() { fixture.close(); }

    function rejects(raw:String, status:Int = 400):Void {
        var actual = 0;
        try { RequestParser.parseFromRawRequest(raw); }
        catch(e:AbortException) { actual = e.statusCode; }
        Assert.equals(status, actual, raw);
    }

    function testAmbiguousOrInvalidFramingIsRejected() {
        var prefix = "POST / HTTP/1.1\r\nHost: localhost\r\n";
        for(value in ["", "-1", "+4", "0x4", "4junk", "4, 4", "4 4", "4\t4", "2147483648", "4294967300", "99999999999999999999"])
            rejects(prefix + "Content-Length: " + value);
        for(headers in [
            "Content-Length: 4\r\nContent-Length: 4", "Content-Length: 4\r\ncontent-length: 0",
            "Content-Length: 4\r\nTransfer-Encoding: chunked", "transfer-encoding:chunked\r\ncOnTeNt-LeNgTh:4",
            "Transfer-Encoding: chunked\r\ntransfer-encoding: identity",
            "Content-Length : 4", " Content-Length: 4", "Content-Length:\u000b4", "Content-Length: 4\nX: x",
            "Content-Length: 4\r\n\tcontinued", "Host: other", "Broken header", "X-Bad\u0000: value"
        ]) rejects(prefix + headers);
        rejects(prefix + "Transfer-Encoding: chunked", 501);
        rejects(prefix + "Transfer-Encoding: identity", 501);
        rejects(prefix + "Content-Length: 1048577", 413);
        for(line in ["POST /", "POST  / HTTP/1.1", "PO\tST / HTTP/1.1", "GET /\t HTTP/1.1", "GET / HTTP/2.0"])
            rejects(line + "\r\nHost: localhost");
    }

    function testValidHeadersAndSingleQueryDecode() {
        var request = RequestParser.parseFromRawRequest("POST /hello%20world?next=%2Fsafe%0D%0ASet-Cookie%3Ax%3D1&literal=%252F&equals=a=b HTTP/1.1\r\nhOsT:localhost\r\ncookie: a=1\r\nCookie: b=2\r\ncontent-length:\t004 \t\r\nX-Url:https://example.com:8443/a\r\nAccept: text/plain\r\naccept: text/html");
        Assert.equals("/hello world", request.path);
        Assert.equals("/safe\r\nSet-Cookie:x=1", request.query("next"));
        Assert.equals("%2F", request.query("literal"));
        Assert.equals("a=b", request.query("equals"));
        Assert.equals("localhost", request.host);
        Assert.equals("1", request.cookie("a"));
        Assert.equals("2", request.cookie("b"));
        Assert.equals("https://example.com:8443/a", request.header("X-URL"));
        Assert.equals("text/plain, text/html", request.header("Accept"));
        Assert.isTrue(RequestParser.isBodyAvailable(request));
        RequestStatic.set(request);
        var input = new BytesInput(Bytes.ofString("DATANEXT"));
        SocketRequestParser.parseBody(request, input);
        Assert.equals("DATA", request.bodyBytes.toString());
        Assert.equals(4, input.position);
    }

    function testIncompleteBodyIsBadRequest() {
        var request = RequestParser.parseFromRawRequest("POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5");
        RequestStatic.set(request);
        var status = 0;
        try { SocketRequestParser.parseBody(request, new BytesInput(Bytes.ofString("abc"))); }
        catch(e:AbortException) { status = e.statusCode; }
        Assert.equals(400, status);
        Assert.isNull(request.bodyBytes);
    }

    function testResponseMetadataRejectsControlsBeforeMutation() {
        var response = new Response().header("Location", "/safe");
        for(value in ["/safe\r\nSet-Cookie: injected=1", "x\rX: y", "x\nX: y", "x\u0000y", "x\u000by", "x\u007fy"]) {
            Assert.raises(() -> response.header("Location", value), Exception);
            Assert.raises(() -> response.withHeaders(["Location" => value]), Exception);
            Assert.raises(() -> ResponseStatic.header("Location", value), Exception);
            Assert.raises(() -> response.status(200, value), Exception);
        }
        Assert.equals("/safe", @:privateAccess response.headers.get("Location"));
        Assert.isFalse(@:privateAccess ResponseStatic.get().headers.exists("Location"));
        for(name in ["", "Bad Name", "X:Bad", "X\r\nInjected", "X\tBad", "X\u007fBad"]) {
            Assert.raises(() -> response.header(name, "ok"), Exception);
            Assert.raises(() -> response.withHeaders([name => "ok"]), Exception);
            Assert.raises(() -> ResponseStatic.header(name, "ok"), Exception);
        }
        response.header("X-Valid", "a\tb: c").status(200, "All good");
        response.validate();
        Assert.equals("a\tb: c", @:privateAccess response.headers.get("X-Valid"));
    }

    function testMutableCookiesAreCheckedAtSerialization() {
        for(name in ["bad=name", "bad;name", "bad\r\nX", ""]) Assert.raises(() -> new CookieData(name, "ok"), Exception);
        for(value in ["x\r\nSet-Cookie: evil=1", "x;y=1", "x,y", "x y", "x\t", "x\u0000", "x\"", "x\\y"])
            Assert.raises(() -> new CookieData("valid", value), Exception);
        for(field in ["value", "path", "domain", "sameSite"]) {
            var cookie = new CookieData("valid", "ok");
            var response = new Response().cookieFromData("valid", cookie);
            Reflect.setField(cookie, field, "x\r\nSet-Cookie: evil=1");
            Assert.raises(() -> cookie.toString(), Exception);
            Assert.raises(() -> response.validate(), Exception);
            Assert.raises(() -> ResponseStatic.cookieFromData("bad", cookie), Exception);
        }
        var response = new Response();
        var builder = response.cookie("token", "a/b+c==");
        builder.secure(false).httpOnly(false).sameSite("Strict").path("/app").domain("example.com").maxAge(60);
        Assert.raises(() -> builder.path("/; Secure"), Exception);
        Assert.raises(() -> builder.domain("x\r\nX: y"), Exception);
        Assert.raises(() -> builder.sameSite("None\r\nX: y"), Exception);
        response.validate();
        Assert.equals("token=a/b+c==; SameSite=Strict; Path=/app; Domain=example.com; Max-Age=60",
            @:privateAccess response.cookies.get("token").toString());
    }
}
