package hx.well.config;
import haxe.ds.StringMap;
using Std;

class DatabaseConfig implements IConfig {
    public function new() {}

    public var connections:StringMap<ConnectionTypedef> = new StringMap();
}