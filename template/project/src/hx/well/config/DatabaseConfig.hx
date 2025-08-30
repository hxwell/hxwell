package hx.well.config;
import haxe.ds.StringMap;
import hx.well.facades.Environment.env;
using Std;

class DatabaseConfig implements IConfig {
    public function new() {}

    public var connections:StringMap<ConnectionTypedef> = [
        "default" => {
            "driver": env("DB_DRIVER", "none"), // mysql, sqlite, none
            "path": env("DB_PATH"), // Only for Local Databases
            "host": env("DB_HOST", "127.0.0.1"),
            "port": env("DB_PORT", "3306").parseInt(),
            "username": env("DB_USERNAME", "root"),
            "password": env("DB_PASSWORD", "root")
        }
    ];
}

typedef ConnectionTypedef = {
    driver:String,
    ?path:String,
    ?host:String,
    ?port:Int,
    ?username:String,
    ?password:String
}