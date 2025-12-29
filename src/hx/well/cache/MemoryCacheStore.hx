package hx.well.cache;
import hx.concurrent.collection.SynchronizedMap;
class MemoryCacheStore implements ICacheStore {
    private var memory:SynchronizedMap<String, MemoryCacheEntry> = SynchronizedMap.newStringMap();

    public function new() {

    }

    public function put<T>(key:String, data:T, seconds:Null<Int>):Void {
        var cacheKey:String = cacheKey(key);
        var cacheData:MemoryCacheEntry = {
            data: data,
            expireAt: seconds == null ? -1 : Sys.time() + seconds
        }
        memory.set(cacheKey, cacheData);
    }

    public function get<T>(key:String, ?defaultValue:T):T {
        var cacheKey:String = cacheKey(key);

        var cacheData:MemoryCacheEntry = memory.get(cacheKey);

        if (cacheData == null || (cacheData.expireAt != -1 && cacheData.expireAt < Sys.time()))
            return defaultValue;

        return cacheData.data;
    }

    public function has(key:String):Bool {
        var cacheKey:String = cacheKey(key);
        return memory.exists(cacheKey);
    }

    public function forget(key:String):Bool {
        var cacheKey:String = cacheKey(key);
        return memory.remove(cacheKey);
    }

    public function cacheKey(key:String):String {
        return key;
    }

    public function forever<T>(key:String, data:T):Void {
        put(key, data, null);
    }

    public function leftTime(key:String):Int {
        var cacheKey:String = cacheKey(key);

        var cacheData:MemoryCacheEntry = memory.get(cacheKey);
        if (cacheData == null || (cacheData.expireAt != -1 && cacheData.expireAt < Sys.time()))
            return 0;

        if (cacheData.expireAt == -1)
            return -1; // Forever cache

        return Math.floor(cacheData.expireAt - Sys.time());
    }

    public function expireCache():Void {
        var expiredKeys:Array<String> = [];

        for (keyValueIterator in memory.keyValueIterator()) {
            var key = keyValueIterator.key;
            var value = keyValueIterator.value;

            if (value.expireAt != -1 && value.expireAt < Sys.time()) {
                expiredKeys.push(key);
            }
        }

        for (expiredKey in expiredKeys) {
            forget(expiredKey);
        }
    }

    public function flush():Void {
        memory.clear();
    }

    public function getMany<T>(keys:Array<String>):Map<String, T> {
        var result:Map<String, T> = new Map();
        for (key in keys) {
            var value:T = get(key);
            if (value != null) {
                result.set(key, value);
            }
        }
        return result;
    }

    public function putMany<T>(values:Map<String, T>, seconds:Null<Int>):Void {
        for (key => value in values) {
            put(key, value, seconds);
        }
    }
}

typedef MemoryCacheEntry = {
    var data:Dynamic;
    var expireAt:Null<Float>;
}