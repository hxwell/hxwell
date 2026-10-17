import utest.UTest;
import hx.well.config.ConfigData;

class TestMain {
    static function main() {
        hx.well.facades.Environment.reset();
        ConfigData.init();

        UTest.run([
            new cases.TestRoutePattern(),
            new cases.TestRoute(),
            new cases.TestResponse(),
            new cases.TestQueryBuilder(),
            new cases.TestSchemaGrammar(),
            new cases.TestEnvironment(),
            new cases.TestConfig(),
            new cases.TestMethodHandler(),
            new cases.TestPipeline(),
            new cases.TestCrypt(),
            new cases.TestCache(),
            new cases.TestPublicHandler(),
            new cases.TestSecurity()
            #if jvm
            , new cases.TestJvmSecurity()
            #end
            #if (neko || hl || cpp || php)
            , new cases.TestDatabase()
            , new cases.TestSchema()
            #end
        ]);
    }
}
