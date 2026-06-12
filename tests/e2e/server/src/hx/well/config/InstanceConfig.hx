package hx.well.config;

import hx.well.server.instance.IInstance;
import hx.well.facades.Environment.Environment.env;
import hx.well.http.driver.socket.SocketInstance;
#if js
import hx.well.http.driver.nodehttp.NodeHttpInstance;
#end
#if java
import hx.well.http.driver.undertow.UndertowInstance;
#end
using Std;

class InstanceConfig implements IConfig {
    public function new() {}

    #if !php
    public function get():Array<IInstance> {
        var host:String = env("HOST", "127.0.0.1");
        var port:Int = env("PORT", "3000").parseInt();

        #if java
        if (env("HXWELL_DRIVER", "socket") == "undertow") {
            return [
                UndertowInstance.builder()
                    .setHost(host)
                    .setPort(port)
                    .build()
            ];
        }
        #end

        return [
            #if js
            NodeHttpInstance.builder()
                .setHost(host)
                .setPort(port)
                .setPoolSize(2)
                .build()
            #else
            SocketInstance.builder()
                .setHost(host)
                .setPort(port)
                .build()
            #end
        ];
    }
    #end
}
