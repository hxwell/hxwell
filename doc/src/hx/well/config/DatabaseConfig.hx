package hx.well.config;
import haxe.ds.StringMap;
import hx.well.facades.Environment.env;
using Std;

class DatabaseConfig implements IConfig {
    public function new() {}

    public var connections:StringMap<ConnectionTypedef> = new StringMap();
}

typedef ConnectionTypedef = {
    driver:String,
    ?path:String,
    ?host:String,
    ?port:Int,
    ?username:String,
    ?password:String
}