package hx.well.pool;

#if (target.threaded)
import sys.thread.Mutex;
abstract class AbstractPool<T> {
    private var objects:Array<T>;
    private var pool:Array<T>;
    private var mutex:Mutex;

    public function new() {
        this.objects = [];
        this.pool = [];
        this.mutex = new Mutex();

        init();
    }

    public function init():Void
    {
        for(i in 0...size())
        {
            var object:T = create();
            objects.push(object);
            pool.push(object);
        }
    }

    public abstract function create():T;

    public abstract function size():Int;

    public function get():T
    {
        mutex.acquire();
        var value:T = null;

        try {
            if(pool.length == 0)
            {
                #if debug
                trace("objectpool is empty!");
                #end
                value = create();
            }else{
                try {
                    value = pool.shift();
                } catch (e) {

                }
            }
            mutex.release();
        } catch (e) {
            mutex.release();

            throw e;
        }

        return value;
    }

    public function free(object:T):Void {
        mutex.acquire();
        try {
            // Only add the pool elements back.
            if(objects.indexOf(object) != -1)
                pool.push(object);
        } catch (e) {

        }
        mutex.release();
    }
}
#else
// Fake Pooling
abstract class AbstractPool<T> {
    private var objects:Array<T>;
    private var pool:Array<T>;

    public function new() {
        this.objects = [];
        this.pool = [];
        init();
    }

    public function init():Void
    {

    }

    public abstract function create():T;

    public abstract function size():Int;

    public function get():T
    {
        return create();
    }

    public function free(object:T):Void {

    }
}
#end