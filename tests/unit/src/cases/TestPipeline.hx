package cases;

import utest.Assert;
import hx.well.HxWell;
import hx.well.http.HttpHandler;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.StringResponse;
import hx.well.http.AbstractResponse;
import hx.well.route.Route;
import hx.well.route.RouteElement;
import hx.well.middleware.AbstractMiddleware;
import hx.well.handler.AbstractHandler;

class PipelineLog {
    public static var entries:Array<String> = [];
}

class TraceMiddlewareA extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        PipelineLog.entries.push("A:before");
        var response = next(request);
        PipelineLog.entries.push("A:after");
        return response;
    }

    public override function dispose():Void {
        PipelineLog.entries.push("A:dispose");
    }
}

class TraceMiddlewareB extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        PipelineLog.entries.push("B:before");
        var response = next(request);
        PipelineLog.entries.push("B:after");
        return response;
    }

    public override function dispose():Void {
        PipelineLog.entries.push("B:dispose");
    }
}

class BlockingMiddleware extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        PipelineLog.entries.push("blocked");
        return new StringResponse("blocked", 403);
    }
}

class FailingValidationHandler extends AbstractHandler {
    public override function validate():Bool {
        return false;
    }

    public function execute(request:Request):AbstractResponse {
        PipelineLog.entries.push("handler-after-validation");
        return "never";
    }
}

class TestPipeline extends utest.Test {
    function setup() {
        Route.routes = [];
        Route.routeByName = new Map();
        RouteElement.groups = [];
        HxWell.middlewares = [];
        PipelineLog.entries = [];
    }

    function context(method:String, path:String):FakeDriverContext {
        var request = new Request();
        request.method = method;
        request.path = path;
        request.host = "localhost:3000";
        return new FakeDriverContext(request);
    }

    function testMiddlewareOrderAndReverseDispose() {
        Route.get("/x", request -> {
            PipelineLog.entries.push("handler");
            return ("ok" : AbstractResponse);
        }).middleware(TraceMiddlewareA).middleware(TraceMiddlewareB);

        var fake = context("GET", "/x");
        HttpHandler.process(fake);

        Assert.same(["A:before", "B:before", "handler", "B:after", "A:after", "B:dispose", "A:dispose"], PipelineLog.entries);
        Assert.equals(1, fake.written.length);
        Assert.equals("ok", fake.written[0].toString());
        Assert.isTrue(fake.closed);
    }

    function testShortCircuitSkipsHandler() {
        Route.get("/x", request -> {
            PipelineLog.entries.push("handler");
            return ("ok" : AbstractResponse);
        }).middleware(BlockingMiddleware).middleware(TraceMiddlewareA);

        var fake = context("GET", "/x");
        HttpHandler.process(fake);

        Assert.same(["blocked"], PipelineLog.entries);
        Assert.equals(403, fake.written[0].statusCode);
    }

    function testGlobalMiddlewareRunsBeforeRouteMiddleware() {
        HxWell.middlewares = [TraceMiddlewareA];
        Route.get("/x", request -> ("ok" : AbstractResponse)).middleware(TraceMiddlewareB);

        HttpHandler.process(context("GET", "/x"));

        Assert.same(["A:before", "B:before", "B:after", "A:after", "B:dispose", "A:dispose"], PipelineLog.entries);
    }

    function testUnknownPathWritesNotFound() {
        var fake = context("GET", "/no-such-path");
        HttpHandler.process(fake);

        Assert.equals(1, fake.written.length);
        Assert.equals(404, fake.written[0].statusCode);
        Assert.isTrue(fake.closed);
    }

    function testMethodMismatchWritesMethodNotAllowed() {
        Route.post("/only-post", request -> ("ok" : AbstractResponse));

        var fake = context("GET", "/only-post");
        HttpHandler.process(fake);

        Assert.equals(405, fake.written[0].statusCode);
    }

    function testFailedValidationWritesUnprocessable() {
        Route.get("/guarded").handler(new FailingValidationHandler());

        var fake = context("GET", "/guarded");
        HttpHandler.process(fake);

        Assert.equals(422, fake.written[0].statusCode);
        Assert.isFalse(PipelineLog.entries.contains("handler-after-validation"));
    }

    function testUnparseableRequestWritesBadRequest() {
        var fake = context("GET", "/x");
        fake.preparedRequest = new Request();
        fake.preparedRequest.path = "/";
        fake.failBuild = true;

        HttpHandler.process(fake);

        Assert.equals(1, fake.written.length);
        Assert.equals(400, fake.written[0].statusCode);
        Assert.isTrue(fake.closed);
    }
}
