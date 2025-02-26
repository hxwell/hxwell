package hx.well.cache;

@:autoBuild(hx.well.macro.CacheMacro.build())
interface ICacheStore {
    function put<T>(key:String, data:T, seconds:Null<Int>):Void;
    function forever<T>(key:String, data:T):Void;
    function get<T>(key:String, ?defaultValue:T):T;
    function leftTime(key:String):Int;
    function has(key:String):Bool;
    function forget(key:String):Bool;
    function cacheKey(key:String):String;
    function expireCache():Void;
}
