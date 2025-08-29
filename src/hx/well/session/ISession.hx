package hx.well.session;
import sys.db.Connection;
interface ISession {
    var expireAt:Int;
    var sessionKey:String;
    var data(null, default):Map<String, Dynamic>;

    function putWithEnum<T>(key:EnumValue, data:T):Void;
    function put<T>(key:String, data:T):Void;
    function getWithEnum<T>(key:EnumValue, ?defaultValue:T):T;
    function get<T>(key:String, ?defaultValue:T):T;
    function hasWithEnum(key:EnumValue):Bool;
    function has(key:String):Bool;
    function forgetWithEnum<T>(key:EnumValue):Void;
    function forget<T>(key:String):Void;
    function flush():Void;
    function save():Void;
}
