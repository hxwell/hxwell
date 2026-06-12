package cases;

import utest.Assert;
import hx.well.route.RoutePattern;

class TestRoutePattern extends utest.Test {
    function testSingleParameter() {
        var pattern = new RoutePattern("/users/{id}");
        var params = pattern.match("/users/42");
        Assert.notNull(params);
        Assert.equals("42", params.get("id"));
    }

    function testMultipleParametersKeepPatternOrder() {
        var pattern = new RoutePattern("/users/{id}/posts/{slug}/rev/{rev}");
        var params = pattern.match("/users/7/posts/hello-world/rev/3");
        Assert.notNull(params);
        Assert.equals("7", params.get("id"));
        Assert.equals("hello-world", params.get("slug"));
        Assert.equals("3", params.get("rev"));
    }

    function testOptionalParameterFilled() {
        var pattern = new RoutePattern("/opt/{name?}");
        var params = pattern.match("/opt/baris");
        Assert.notNull(params);
        Assert.equals("baris", params.get("name"));
    }

    function testOptionalParameterMissing() {
        var pattern = new RoutePattern("/opt/{name?}");
        var params = pattern.match("/opt");
        Assert.notNull(params);
        Assert.isFalse(params.exists("name"));
    }

    function testRequiredThenOptional() {
        var pattern = new RoutePattern("/a/{x}/{y?}");
        var both = pattern.match("/a/1/2");
        Assert.equals("1", both.get("x"));
        Assert.equals("2", both.get("y"));

        var single = pattern.match("/a/1");
        Assert.equals("1", single.get("x"));
        Assert.isFalse(single.exists("y"));
    }

    function testInlineConstraint() {
        var pattern = new RoutePattern("/n/{id:[0-9]+}");
        Assert.notNull(pattern.match("/n/123"));
        Assert.isNull(pattern.match("/n/abc"));
    }

    function testAddConstraint() {
        var pattern = new RoutePattern("/abort/{code}");
        pattern.addConstraint("code", "[1-5][0-9]{2}");
        Assert.notNull(pattern.match("/abort/404"));
        Assert.isNull(pattern.match("/abort/999"));
    }

    function testQueryStringIgnored() {
        var pattern = new RoutePattern("/users/{id}");
        var params = pattern.match("/users/42?page=1");
        Assert.notNull(params);
        Assert.equals("42", params.get("id"));
    }

    function testNoMatch() {
        var pattern = new RoutePattern("/users/{id}");
        Assert.isNull(pattern.match("/posts/42"));
    }
}
