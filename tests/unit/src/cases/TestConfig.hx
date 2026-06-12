package cases;

import utest.Assert;
import hx.well.facades.Config;
import hx.well.facades.Config.config;
import hx.well.config.ConfigData;

class TestConfig extends utest.Test {
    function testGet() {
        Assert.equals(8192, Config.get("http.max_buffer"));
        Assert.equals("public", Config.get("http.public_path"));
        Assert.equals(360, Config.get("session.lifetime"));
    }

    function testConfigHelper() {
        Assert.equals(8192, config("http.max_buffer"));
    }

    function testSet() {
        var original:Int = Config.get("http.max_buffer");
        Config.set("http.max_buffer", 1234);
        Assert.equals(1234, Config.get("http.max_buffer"));
        Config.set("http.max_buffer", original);
    }

    function testGeneratedFields() {
        Assert.notNull(ConfigData.httpconfig);
        Assert.notNull(ConfigData.sessionconfig);
        Assert.notNull(ConfigData.databaseconfig);
        Assert.notNull(ConfigData.middlewareconfig);
        Assert.notNull(ConfigData.providerconfig);
        Assert.notNull(ConfigData.instanceconfig);
    }

    function testMiddlewareAndProviderLists() {
        Assert.equals(0, ConfigData.middlewareconfig.get().length);
        Assert.equals(0, ConfigData.providerconfig.get().length);
    }
}
