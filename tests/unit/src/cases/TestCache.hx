package cases;

import utest.Assert;
import hx.well.facades.Cache;
import hx.well.cache.MemoryCacheStore;

class TestCache extends utest.Test {
    function store():Cache {
        var cache = Cache.store(MemoryCacheStore);
        cache.flush();
        return cache;
    }

    function testPutGet() {
        var cache = store();
        cache.put("answer", 42, 60);
        Assert.equals(42, cache.get("answer"));
        Assert.isTrue(cache.has("answer"));
    }

    function testDefaultValue() {
        var cache = store();
        Assert.equals("fallback", cache.get("missing", "fallback"));
        Assert.isFalse(cache.has("missing"));
    }

    function testForget() {
        var cache = store();
        cache.put("temp", "x", 60);
        cache.forget("temp");
        Assert.isFalse(cache.has("temp"));
    }

    function testPull() {
        var cache = store();
        cache.put("once", "value", 60);
        Assert.equals("value", cache.pull("once", null));
        Assert.isFalse(cache.has("once"));
    }

    function testRemember() {
        var cache = store();
        var calls = 0;
        var producer = () -> {
            calls++;
            return "produced";
        };
        Assert.equals("produced", cache.remember("memo", 60, producer));
        Assert.equals("produced", cache.remember("memo", 60, producer));
        Assert.equals(1, calls);
    }

    function testIncrementDecrement() {
        var cache = store();
        cache.put("count", 10, 60);
        cache.increment("count", 5);
        cache.decrement("count");
        Assert.equals(14, cache.get("count"));
    }

    #if sys
    function testExpiry() {
        var cache = store();
        cache.put("short", "lived", 1);
        Assert.isTrue(cache.has("short"));
        Sys.sleep(1.2);
        Assert.isFalse(cache.has("short"));
    }
    #end
}
