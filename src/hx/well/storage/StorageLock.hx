package hx.well.storage;

/** Bounded locks shared by disk instances, including separately built local
    disks for the same root. Used for append/prepend read-modify-write cycles. */
class StorageLock {
    #if target.threaded
    static var locks = [for (_ in 0...64) new sys.thread.Mutex()];
    #end

    public static function run<T>(key:String, callback:Void->T):T {
        #if target.threaded
        var hash = 0;
        for (i in 0...key.length) hash = ((hash * 31) + (key.charCodeAt(i) | 0)) & 63;
        var lock = locks[hash];
        lock.acquire();
        try {
            var result = callback();
            lock.release();
            return result;
        } catch (e:Dynamic) {
            lock.release();
            throw e;
        }
        #else
        return callback();
        #end
    }
}
