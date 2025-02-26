package hx.well.database;
import haxe.ThreadLocal;
import hx.well.pool.DatabasePool;
import sys.db.Connection as HaxeConnection;
import hx.concurrent.collection.SynchronizedMap;
class Connection {
    private static var connectionPool:SynchronizedMap<String, DatabasePool> = SynchronizedMap.newStringMap();
    private static var threadLocal:ThreadLocal<Map<String, HaxeConnection>> = new ThreadLocal<Map<String, HaxeConnection>>(() -> {
        return new Map<String, HaxeConnection>();
    },(connections:Map<String, HaxeConnection>) -> {
        for(key in connections.keys())
        {
            var connection = connections.get(key);
            connectionPool.get(key).free(connection);
        }
        #if debug
        trace("free connection");
        #end
    });

    public static function create(key:String, config:Dynamic):Void
    {
        var databasePool:DatabasePool = new DatabasePool(key, config);
        connectionPool.set(key, databasePool);
        #if debug
        trace('${key} => ${databasePool} ${connectionPool.get(key)}');
        #end
    }

    private static function getConnectionFromPool(key:String):HaxeConnection {
        return connectionPool.get(key).get();
    }

    public static function get(key:String = "default"):HaxeConnection
    {
        var connections = threadLocal.get();

        if(!connections.exists(key))
            connections.set(key, getConnectionFromPool(key));

        return connections.get(key);
    }

    public static function connectionKeys():Array<String> {
        return [for(connectionKey in connectionPool.keys()) connectionKey];
    }

    public static function free():Void
    {
        threadLocal.remove();
    }
}
