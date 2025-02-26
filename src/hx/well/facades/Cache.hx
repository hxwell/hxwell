package hx.well.facades;
import hx.well.facades.Cache;
import hx.well.cache.ICacheStore;
import hx.well.cache.FileSystemCacheStore;
import hx.concurrent.collection.SynchronizedMap;
class Cache {
    private static var cacheInstanceMap:Map<String, Cache> = [];
    public static var cacheStores:Array<Class<ICacheStore>> = [];

    public static function store(?cacheStoreClass:Class<ICacheStore>):Cache {
        if(cacheStoreClass == null)
            cacheStoreClass = FileSystemCacheStore;

        var cacheStoreClassName:String = Type.getClassName(cacheStoreClass);

        var instance:Cache = cacheInstanceMap.get(cacheStoreClassName);

        if(instance == null)
            cacheInstanceMap.set(cacheStoreClassName, instance = new Cache(Type.createInstance(cacheStoreClass, [])));

        return instance;
    }

    private var cacheStore:ICacheStore = new FileSystemCacheStore();
    public function new(cacheStore:ICacheStore)
    {
        this.cacheStore = cacheStore;
    }


    public function get<T>(key:String, ?defaultValue:T):T {
        return cacheStore.get(key, defaultValue);
    }

    public function has(key:String):Bool {
        return cacheStore.has(key);
    }

    public function put<T>(key:String, data:T, seconds:Int):Void {
        return cacheStore.put(key, data, seconds);
    }

    public function pull<T>(key:String, defaultValue:T):T {
        if(!has(key))
            return defaultValue;

        var value:T = get(key);
        forget(key);
        return value;
    }

    public function remember<T>(key:String, seconds:Int, callback:Void->T):T
    {
        var value:T = callback();
        put(key, value, seconds);
        return value;
    }

    public function forget<T>(key:String):Bool {
        return cacheStore.forget(key);
    }

    public function increment(key:String, amount:Int = 1):Void {
        if(!has(key))
            return;

        put(key, get(key, 0) + amount, cacheStore.leftTime(key));
    }

    public function decrement(key:String, amount:Int = 1):Void {
        if(!has(key))
            return;

        put(key, get(key, 0) - amount, cacheStore.leftTime(key));
    }

    public function forever<T>(key:String, value:T):Void {
        cacheStore.forever(key, value);
    }

    public function cacheKey(key:String):String {
        return cacheStore.cacheKey(key);
    }

    public function expireCache():Void {
        cacheStore.expireCache();
    }
}
