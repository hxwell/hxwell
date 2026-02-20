package hx.well.session;
import sys.db.Connection;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.facades.Cache;
import hx.well.facades.Config;
class Session implements ISession {
    public var expireAt:Int;
    public var sessionKey:String;
    public var needsRefresh:Bool = true;
    public var data(null, default):Map<String, Dynamic>;

    private var isModified:Bool = false;

    public function new() {

    }

    public function putWithEnum<T>(key:EnumValue, data:T):Void {
        @:inline put('${key}', data);
    }

    public function put<T>(key:String, data:T):Void {
        isModified = true;
        this.data.set(key, data);
    }

    public function getWithEnum<T>(key:EnumValue, ?defaultValue:T):T {
        return @:inline get('${key}', defaultValue);
    }

    public function get<T>(key:String, ?defaultValue:T):T {
        return this.data.get(key) ?? defaultValue;
    }

    public function hasWithEnum(key:EnumValue):Bool {
        return @:inline has('${key}');
    }

    public function has(key:String):Bool {
        return this.data.exists(key);
    }

    public function forgetWithEnum(key:EnumValue):Void {
        return @:inline forget('${key}');
    }

    public function forget<T>(key:String):Void {
        isModified = true;
        this.data.remove(key);
    }

    public function flush():Void {
        isModified = true;
        this.data.clear();
    }

    public function save():Bool {
        if (!isModified)
            return false;
        isModified = false;
        Cache.store(FileSystemSessionCacheStore).put('session.${sessionKey}', data, Config.get("session.lifetime") * 60);
        return true;
    }

    public function touch():Void {
        var seconds:Int = Config.get("session.lifetime") * 60;
        var touched = Cache.store(FileSystemSessionCacheStore).touch('session.${sessionKey}', seconds);
        if (!touched) {
            Cache.store(FileSystemSessionCacheStore).put('session.${sessionKey}', data, seconds);
        }
        isModified = false;
    }
}
