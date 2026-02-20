package hx.well.thread;

#if (target.threaded)
import sys.thread.Mutex;
#else
import hx.well.thread.FakeMutex as Mutex;
#end

class MutexPool {
    private var keyMap:Map<String, MutexEntry> = new Map();
    private var pool:Array<Mutex> = [];
    private var globalMutex:Mutex = new Mutex();

    public function new() {}

    public function acquire(key:String):Void {
        globalMutex.acquire();
        var entry = keyMap.get(key);
        if(entry == null) {
            var m = pool.length > 0 ? pool.pop() : new Mutex();
            entry = {mutex: m, refCount: 0};
            keyMap.set(key, entry);
        }
        entry.refCount++;
        var m = entry.mutex;
        globalMutex.release();
        m.acquire();
    }

    public function release(key:String):Void {
        globalMutex.acquire();
        var entry = keyMap.get(key);
        if(entry != null) {
            entry.mutex.release();
            entry.refCount--;
            if (entry.refCount <= 0) {
                keyMap.remove(key);
                pool.push(entry.mutex);
            }
        }
        globalMutex.release();
    }
}

private typedef MutexEntry = {
    mutex:Mutex,
    refCount:Int
}
