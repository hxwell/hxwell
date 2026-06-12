package cases;

import utest.Assert;
import hx.well.facades.Environment;
import haxe.ds.StringMap;

class TestEnvironment extends utest.Test {
    function setup() {
        Environment.reset();
    }

    function testSetGetExists() {
        Assert.isFalse(Environment.exists("FOO"));
        Environment.set("FOO", "bar");
        Assert.isTrue(Environment.exists("FOO"));
        Assert.equals("bar", Environment.get("FOO"));
    }

    function testDefaultValue() {
        Assert.equals("fallback", Environment.get("MISSING", "fallback"));
        Assert.isNull(Environment.get("MISSING"));
    }

    function testExpandBraced() {
        var data:StringMap<String> = ["HOST" => "localhost"];
        Assert.equals("http://localhost/", Environment.expandEnvVars("http://${HOST}/", data));
    }

    function testExpandDollar() {
        var data:StringMap<String> = ["USER" => "baris"];
        Assert.equals("hi baris!", Environment.expandEnvVars("hi $USER!", data));
    }

    function testExpandMissingBecomesEmpty() {
        var data:StringMap<String> = new StringMap();
        Assert.equals("x--y", Environment.expandEnvVars("x-${NOPE}-y", data));
    }

    function testExpandSelfReferenceTerminates() {
        var data:StringMap<String> = ["LOOP" => "${LOOP}"];
        var result = Environment.expandEnvVars("${LOOP}", data);
        Assert.notNull(result);
    }

    function testExpandChained() {
        var data:StringMap<String> = ["A" => "B", "B" => "ignored"];
        Assert.equals("B", Environment.expandEnvVars("${A}", data));
    }
}
