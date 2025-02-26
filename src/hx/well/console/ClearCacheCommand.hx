package hx.well.console;
import hx.well.database.Connection;
import haxe.CallStack;
import haxe.Exception;
import haxe.ds.Either;
import hx.well.facades.Cache;
import hx.well.facades.Cache;
class ClearCacheCommand extends AbstractCommand {
    public override function group():String {
        return "cache";
    }

    public function signature():String {
        return "clear";
    }

    public function description():String {
        return "clears outdated caches";
    }

    public function handle<T>():Null<T> {
        for(cacheInstance in @:privateAccess Cache.cacheInstanceMap) {
            cacheInstance.expireCache();
        }

        return null;
    }
}

