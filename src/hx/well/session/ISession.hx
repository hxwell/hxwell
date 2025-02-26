package hx.well.session;
import sys.db.Connection;
interface ISession {
    var sessionKey:String;
    var data(null, default):Map<String, Dynamic>;

    function put<T>(key:String, data:T):Void;
    function get<T>(key:String, ?defaultValue:T):T;
    function has(key:String):Bool;
    function forget<T>(key:String):Void;
    function flush():Void;
    function save():Void;
}
