package cases;

import hx.well.auth.IAuthenticatable;
import hx.well.facades.Config;
import hx.well.http.RequestStatic;
import hx.well.http.Response;
import hx.well.route.Route;
import hx.well.type.AttributeType;
import utest.Assert;

class TestAuthMiddleware extends utest.Test {
    var fixture:SecurityFixture;
    var guards:haxe.ds.StringMap<Class<IAuthenticatable>>;
    function setup() {
        fixture = new SecurityFixture();
        guards = Config.get("session.guards");
        Config.set("session.guards", ["default" => GuardUser, "admin" => GuardUser]);
        Route.get("/login").name("login");
    }
    function teardown() {
        Config.set("session.guards", guards);
        fixture.close();
    }
    function testClassRegisteredConstGuardsStaySeparate() {
        var request = SecurityFixture.request();
        RequestStatic.set(request);
        request.setAttribute(AttributeType.Auth("default"), new GuardUser());
        var member:hx.well.middleware.AbstractMiddleware = Type.createInstance(MemberGate, []);
        var admin:hx.well.middleware.AbstractMiddleware = Type.createInstance(AdminGate, []);
        Assert.equals(202, member.handle(request, _ -> new Response(202)).statusCode);
        Assert.equals("default", request.currentGuard());
        var reached = false;
        var denied = admin.handle(request, _ -> { reached = true; return new Response(202); });
        Assert.isFalse(reached);
        Assert.equals(302, denied.statusCode);
        Assert.equals("/login", @:privateAccess denied.headers.get("Location"));
        Assert.equals("admin", request.currentGuard());
        request.setAttribute(AttributeType.Auth("admin"), new GuardUser());
        Assert.equals(202, admin.handle(request, _ -> new Response(202)).statusCode);
    }
}

private class MemberGate extends hx.well.middleware.RequireAuthMiddleware<"default"> {
    public function new() { super(); }
}
private class AdminGate extends hx.well.middleware.RequireAuthMiddleware<"admin"> {
    public function new() { super(); }
}
private class GuardUser implements IAuthenticatable {
    public function new() {}
    public function getId():Dynamic { return 1; }
    public function getPassword():String { return ""; }
}
