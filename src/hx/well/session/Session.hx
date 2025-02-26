package hx.well.session;
import sys.db.Connection;
import hx.well.cache.FileSystemSessionCacheStore;
import hx.well.facades.Cache;
import hx.well.facades.Config;
class Session implements ISession {
    public var sessionKey:String;
    public var data(null, default):Map<SessionEnum, Dynamic>;

    private var isModified:Bool = false;

    public function new() {

    }

    public function put<T>(key:SessionEnum, data:T):Void {
        isModified = true;
        this.data.set(key, data);
    }

    public function get<T>(key:SessionEnum, ?defaultValue:T):T {
        return this.data.get(key);
    }

    public function has(key:SessionEnum):Bool {
        return this.data.exists(key);
    }

    public function forget<T>(key:SessionEnum):Void {
        isModified = true;
        this.data.remove(key);
    }

    public function flush():Void {
        isModified = true;
        this.data.clear();
    }

    public function save():Void {
        if(isModified)
            Cache.store(FileSystemSessionCacheStore).put('session.${sessionKey}', data, Config.get("session.timeout", 1024));
    }
}
