package cases;

import utest.Assert;
import hx.well.http.Response;
import hx.well.http.StringResponse;
import hx.well.http.JsonResponse;
import hx.well.http.AbstractResponse;
import hx.well.http.CookieData;

class TestResponse extends utest.Test {
    function testStringResponse() {
        var response = new StringResponse("hello", 201);
        Assert.equals("hello", response.toString());
        Assert.equals(201, response.statusCode);
        Assert.equals("text/html", @:privateAccess response.headers.get("Content-Type"));
    }

    function testJsonResponse() {
        var response = new JsonResponse({hello: "world", n: 42});
        Assert.equals("application/json", @:privateAccess response.headers.get("Content-Type"));

        var parsed = haxe.Json.parse(response.toString());
        Assert.equals("world", parsed.hello);
        Assert.equals(42, parsed.n);
    }

    function testHeaderChaining() {
        var response = new Response()
            .header("X-One", "1")
            .header("X-Two", "2");

        Assert.equals("1", @:privateAccess response.headers.get("X-One"));
        Assert.equals("2", @:privateAccess response.headers.get("X-Two"));
    }

    function testWithHeaders() {
        var response = new Response().withHeaders(["X-A" => "a", "X-B" => "b"]);
        Assert.equals("a", @:privateAccess response.headers.get("X-A"));
        Assert.equals("b", @:privateAccess response.headers.get("X-B"));
    }

    function testStatus() {
        var response = new Response().status(404, "not found");
        Assert.equals(404, response.statusCode);
        Assert.equals("not found", @:privateAccess response.statusMessage);
    }

    function testCookieSetAndRemove() {
        var response = new Response();
        response.cookie("session", "abc");
        Assert.isTrue(@:privateAccess response.cookies.exists("session"));

        response.cookie("session", null);
        Assert.isFalse(@:privateAccess response.cookies.exists("session"));
    }

    function testCookieDataToString() {
        var cookieData = new CookieData("token", "xyz");
        Assert.equals("token=xyz; Secure; HttpOnly; Path=/", cookieData.toString());
    }

    function testCookieDataAttributes() {
        var cookieData = new CookieData("token", "xyz");
        cookieData.secure = false;
        cookieData.httpOnly = false;
        cookieData.sameSite = "Strict";
        cookieData.domain = "example.com";
        cookieData.maxAge = 60;
        Assert.equals("token=xyz; SameSite=Strict; Path=/; Domain=example.com; Max-Age=60", cookieData.toString());
    }

    function testAbstractResponseFromString() {
        var response:Response = ("plain":AbstractResponse);
        Assert.isOfType(response, StringResponse);
        Assert.equals("plain", response.toString());
    }

    function testAbstractResponseFromNull() {
        var response:Response = AbstractResponse.convert(null);
        Assert.isOfType(response, StringResponse);
        Assert.equals("", response.toString());
    }

    function testAbstractResponseFromInt() {
        var response:Response = AbstractResponse.convert(42);
        Assert.equals("42", response.toString());
    }

    function testAbstractResponsePassthrough() {
        var original:Response = new JsonResponse({a: 1});
        var response:Response = AbstractResponse.convert(original);
        Assert.equals(original, response);
    }
}
