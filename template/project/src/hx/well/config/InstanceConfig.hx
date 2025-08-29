package hx.well.config;
import hx.well.server.instance.IInstance;
import hx.well.http.driver.socket.SocketInstance;
#if js
import hx.well.http.driver.nodehttp.NodeHttpInstance;
#end

class InstanceConfig implements IConfig {
    public function new() {}

    #if !php
    public function get():Array<IInstance> {
        return [
            #if js
            NodeHttpInstance.builder()
                .setHost("0.0.0.0")
                .setPort(3000)
                .build()
            #else
            SocketInstance.builder()
                .setHost("0.0.0.0")
                .setPort(3000)
                .build()
            #end
        ];
    }
    #end
}