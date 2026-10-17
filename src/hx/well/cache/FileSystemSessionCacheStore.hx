package hx.well.cache;
import hx.well.facades.Config;
import sys.FileSystem;
import hx.well.thread.MutexPool;

class FileSystemSessionCacheStore extends FileSystemCacheStore {
    // Shared across store instances: check-and-write must be atomic with revoke.
    private static var sessionLocks = new MutexPool();

    public override function get_path():String {
        return Config.get("session.path");
    }

    private function locked<T>(key:String, action:Void->T):T {
        var lockKey = FileSystem.fullPath(path) + ":" + key;
        sessionLocks.acquire(lockKey);
        try {
            var result = action();
            sessionLocks.release(lockKey);
            return result;
        } catch (e:Dynamic) {
            sessionLocks.release(lockKey);
            throw e;
        }
    }

    private function isRevoked(key:String):Bool {
        return super.has("revoked." + key);
    }

    public override function get<T>(key:String, ?defaultValue:T):T {
        return locked(key, () -> getActive(key, defaultValue));
    }

    private function getActive<T>(key:String, defaultValue:T):T {
        return isRevoked(key) ? defaultValue : super.get(key, defaultValue);
    }

    public override function has(key:String):Bool {
        return locked(key, () -> hasActive(key));
    }

    private function hasActive(key:String):Bool {
        return !isRevoked(key) && super.has(key);
    }

    public override function put<T>(key:String, data:T, seconds:Null<Int>):Void {
        locked(key, () -> putActive(key, data, seconds));
    }

    private function putActive<T>(key:String, data:T, seconds:Null<Int>):Bool {
        if(isRevoked(key))
            return false;
        super.put(key, data, seconds);
        return true;
    }

    public override function touch(key:String, seconds:Null<Int>):Bool {
        return locked(key, () -> touchActive(key, seconds));
    }

    private function touchActive(key:String, seconds:Null<Int>):Bool {
        return !isRevoked(key) && super.touch(key, seconds);
    }

    public override function forget(key:String):Bool {
        return locked(key, () -> revoke(key));
    }

    private function revoke(key:String):Bool {
        // Keep the revocation until every cookie issued before it has expired.
        // Write it first, and fail closed if it cannot be persisted.
        super.put("revoked." + key, true, Config.get("session.lifetime") * 60);
        return super.forget(key);
    }
}
