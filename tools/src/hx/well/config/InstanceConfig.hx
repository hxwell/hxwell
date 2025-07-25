package hx.well.config;
import hx.well.server.instance.IInstance;

class InstanceConfig {
    #if !php
    public static function get():Array<IInstance> {
        return [];
    }
    #end
}