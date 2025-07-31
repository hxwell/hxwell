package hx.well.http.driver.nodehttp;

#if js
import hx.well.server.instance.IInstance;

class NodeHttpInstanceBuilder extends AbstractInstanceBuilder<NodeHttpInstanceBuilder, NodeHttpDriverConfig> {
    private function new() {
        super(new NodeHttpDriverConfig());
    }

    public function build():IInstance {
        return new NodeHttpInstance(config);
    }
}
#end