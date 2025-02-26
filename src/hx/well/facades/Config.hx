package hx.well.facades;

import hx.well.facades.Config;
import hx.concurrent.collection.SynchronizedMap;
class Config {
    private static var data:SynchronizedMap<String, Dynamic> = SynchronizedMap.newStringMap();

    public static function get<T>(key:String, defaultValue:T):T {
        return data.exists(key) ? data.get(key) : defaultValue;
    }

    public static function set<T>(key:String, value:T):Void {
        data.set(key, value);
    }

    public static function remove(key:String):Bool {
        return data.remove(key);
    }
}