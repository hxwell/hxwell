package hx.well.http.driver.undertow;

import hx.well.server.instance.AbstractInstance;

class UndertowInstance extends AbstractInstance<UndertowDriver, UndertowDriverConfig> {
    public static function builder():UndertowInstanceBuilder {
        return @:privateAccess new UndertowInstanceBuilder();
    }

    // Bu metodun AbstractInstance'da da güncellenmesi gerekir.
    public function driver():UndertowDriver {
        return new UndertowDriver(config);
    }
}