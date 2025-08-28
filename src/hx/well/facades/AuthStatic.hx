package hx.well.facades;

import hx.well.http.RequestStatic.request;
import hx.well.http.RequestStatic.auth;
import hx.well.auth.IAuthenticatable;
import haxe.ds.StringMap;

class AuthStatic {
    public static inline function user<T>():T {
        return request().user();
    }

    public static inline function id():Null<Dynamic> {
        return auth().id();
    }

    public static inline function check():Bool {
        return auth().check();
    }

    public static inline function attempt(credentials:StringMap<Dynamic>):Bool {
        return auth().attempt(credentials);
    }

    public static inline function login(authenticable:IAuthenticatable):Void {
        auth().login(authenticable);
    }

    public static inline function logout():Void {
        auth().logout();
    }
}