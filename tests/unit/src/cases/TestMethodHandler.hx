package cases;

import utest.Assert;
import hx.well.handler.MethodHandler;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.AbstractResponse;
import hx.well.validator.ValidatorRule;
import hx.well.exception.AbortException;

class FixtureHandler extends MethodHandler {
    @:get
    @:post
    @:validator("data", [ValidatorRule.Required])
    public function hello(request:Request):AbstractResponse {
        return "hello";
    }

    @:put
    @:delete
    public function update(request:Request):AbstractResponse {
        return "updated";
    }

    @:any
    public function anything(request:Request):AbstractResponse {
        return "any";
    }
}

class TestMethodHandler extends utest.Test {
    function request(method:String, path:String):Request {
        var request = new Request();
        request.method = method;
        request.path = path;
        return request;
    }

    function testMultiVerbRegistration() {
        var handler = new FixtureHandler();
        Assert.isTrue(handler.methods.exists("hello"));
        Assert.contains("GET", handler.methods.get("hello").methods);
        Assert.contains("POST", handler.methods.get("hello").methods);
    }

    function testValidatorsPreservedWithMultipleVerbs() {
        var handler = new FixtureHandler();
        var validators = handler.methods.get("hello").validators;
        Assert.isTrue(validators.exists("data"));
        Assert.equals(1, validators.get("data").length);
    }

    function testNewVerbs() {
        var handler = new FixtureHandler();
        Assert.contains("PUT", handler.methods.get("update").methods);
        Assert.contains("DELETE", handler.methods.get("update").methods);
    }

    function testAnyVerb() {
        var handler = new FixtureHandler();
        Assert.equals(1, handler.methods.get("anything").methods.length);
        Assert.contains("ANY", handler.methods.get("anything").methods);
    }

    function testExecuteDispatch() {
        var handler = new FixtureHandler();
        var response:Response = handler.execute(request("GET", "/api/hello"));
        Assert.equals("hello", response.toString());
    }

    function testExecuteAnyMethod() {
        var handler = new FixtureHandler();
        var response:Response = handler.execute(request("PATCH", "/api/anything"));
        Assert.equals("any", response.toString());
    }

    function testExecuteMethodNotAllowed() {
        var handler = new FixtureHandler();
        Assert.raises(() -> handler.execute(request("PATCH", "/api/hello")), AbortException);
    }

    function testExecuteUnknownMethod() {
        var handler = new FixtureHandler();
        Assert.raises(() -> handler.execute(request("GET", "/api/nope")), AbortException);
    }
}
