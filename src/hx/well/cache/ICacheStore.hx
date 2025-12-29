package hx.well.cache;

/**
 * Cache store interface for different cache backends.
 * Implementations: FileSystemCacheStore, MemoryCacheStore
 */
interface ICacheStore {
    /**
	 * Store data with TTL (time-to-live)
	 * @param key Cache key
	 * @param data Data to store
	 * @param seconds Time to live in seconds, null for forever
	 */
    function put<T>(key:String, data:T, seconds:Null<Int>):Void;

    /**
	 * Store data forever (no expiration)
	 */
    function forever<T>(key:String, data:T):Void;

    /**
	 * Get cached data
	 * @param key Cache key
	 * @param defaultValue Value to return if key not found or expired
	 * @return Cached data or defaultValue
	 */
    function get<T>(key:String, ?defaultValue:T):T;

    /**
	 * Get remaining TTL for a key
	 * @return Remaining seconds, 0 if expired or not found, -1 if forever
	 */
    function leftTime(key:String):Int;

    /**
	 * Check if key exists in cache
	 */
    function has(key:String):Bool;

    /**
	 * Remove a key from cache
	 * @return true if removed successfully
	 */
    function forget(key:String):Bool;

    /**
	 * Generate cache key (typically hashed)
	 */
    function cacheKey(key:String):String;

    /**
	 * Clean up expired cache entries
	 */
    function expireCache():Void;

    /**
	 * Flush all cache entries
	 */
    function flush():Void;

    /**
	 * Get multiple values at once
	 * @param keys Array of cache keys
	 * @return Map of key -> value pairs
	 */
    function getMany<T>(keys:Array<String>):Map<String, T>;

    /**
	 * Store multiple values at once
	 * @param values Map of key -> value pairs
	 * @param seconds Time to live in seconds
	 */
    function putMany<T>(values:Map<String, T>, seconds:Null<Int>):Void;
}
