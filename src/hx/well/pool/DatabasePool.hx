package hx.well.pool;
import sys.db.Connection;

class DatabasePool extends AbstractPool<Connection> {
    private var key:String;
    private var config:Dynamic;

    public function new(key:String, config:Dynamic) {
        this.key = key;
        this.config = config;

        super();
    }

    public function create():Connection {
        if(this.config.path != null)
            return sys.db.Sqlite.open(this.config.path);
        else
            return sys.db.Mysql.connect(this.config);
    }

    public function size():Int {
        return 0;
    }

    public override function free(object:Connection):Void {
        #if !php
        mutex.acquire();
        try {
            // Only add the pool elements back.
            if(objects.indexOf(object) == -1)
                object.close();
        } catch (e) {

        }
        mutex.release();

        super.free(object);
        #end
    }
}