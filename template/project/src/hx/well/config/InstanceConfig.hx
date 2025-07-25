package hx.well.config;
import hx.well.server.instance.IInstance;
import hx.well.http.driver.socket.SocketInstance;

class InstanceConfig {
    #if !php
    public static function get():Array<IInstance> {
        return [
            SocketInstance.builder()
            .setHost("0.0.0.0")
            .setPort(3000)
            .build()
        ];
    }
    #end
}