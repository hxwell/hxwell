package hx.well.http.driver.nodehttp;

#if js
import hx.well.server.instance.AbstractInstance;

class NodeHttpInstance extends AbstractInstance<NodeHttpDriver, NodeHttpDriverConfig> {
    public static function builder():NodeHttpInstanceBuilder {
        return @:privateAccess new NodeHttpInstanceBuilder();
    }

    public function driver():NodeHttpDriver {
        return new NodeHttpDriver(config);
    }
}
#end