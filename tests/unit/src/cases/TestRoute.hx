package cases;

import utest.Assert;
import hx.well.route.Route;
import hx.well.route.RouteElement;
import hx.well.http.Request;
import hx.well.http.Response;
import haxe.http.HttpMethod;

class TestRoute extends utest.Test {
    function setup() {
        Route.routes = [];
        Route.routeByName = new Map();
        RouteElement.groups = [];
    }

    function request(method:String, path:String, host:String = "localhost:3000"):Request {
        var request = new Request();
        request.method = method;
        request.path = path;
        request.host = host;
        return request;
    }

    function testResolveByMethodAndPath() {
        Route.get("/a");
        Route.post("/a");

        var resolved = Route.resolveRequest(request("GET", "/a"));
        Assert.notNull(resolved);
        Assert.contains(HttpMethod.Get, resolved.route.getMethods());

        Assert.isNull(Route.resolveRequest(request("GET", "/b")));
    }

    function testResolveParams() {
        Route.get("/users/{id}/posts/{slug}");
        var resolved = Route.resolveRequest(request("GET", "/users/9/posts/hi"));
        Assert.notNull(resolved);
        Assert.equals("9", resolved.params.get("id"));
        Assert.equals("hi", resolved.params.get("slug"));
    }

    function testTrailingSlash() {
        Route.get("/a");
        Assert.notNull(Route.resolveRequest(request("GET", "/a/")));
    }

    function testClosureAction() {
        Route.get("/closure", request -> "ok");
        var resolved = Route.resolveRequest(request("GET", "/closure"));
        Assert.notNull(resolved.route.getHandler());
        var response:Response = resolved.route.getHandler().execute(request("GET", "/closure"));
        Assert.equals("ok", response.toString());
    }

    function testAllowedMethods() {
        Route.get("/m");
        Route.post("/m");
        Route.get("/other");

        var allowed = Route.allowedMethods(request("PUT", "/m"));
        Assert.contains(HttpMethod.Get, allowed);
        Assert.contains(HttpMethod.Post, allowed);
        Assert.equals(2, allowed.length);

        Assert.equals(0, Route.allowedMethods(request("PUT", "/none")).length);
    }

    function testGroupPrefixAndMiddleware() {
        Route.path("/admin").group(() -> {
            Route.get("/users");
        });

        Assert.notNull(Route.resolveRequest(request("GET", "/admin/users")));
        Assert.isNull(Route.resolveRequest(request("GET", "/users")));
    }

    function testNamedRoute() {
        Route.get("/x").name("x");
        Assert.isTrue(Route.routeByName.exists("x"));
        Assert.raises(() -> Route.get("/y").name("x"), String);
    }

    function testWhereConstraint() {
        Route.get("/abort/{code}").where("code", "[1-5][0-9]{2}");
        Assert.notNull(Route.resolveRequest(request("GET", "/abort/404")));
        Assert.isNull(Route.resolveRequest(request("GET", "/abort/999")));
    }

    function testWhereWithoutPathRaises() {
        Assert.raises(() -> Route.name("broken").where("id", "[0-9]+"), String);
    }

    function testDomainRouting() {
        Route.domain("{sub}.example.com").path("/d");
        var resolved = Route.resolveRequest(request("GET", "/d", "api.example.com:80"));
        Assert.notNull(resolved);
        Assert.equals("api", resolved.params.get("sub"));

        Assert.isNull(Route.resolveRequest(request("GET", "/d", "example.org:80")));
    }
}
