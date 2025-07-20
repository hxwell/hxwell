package hx.well.console;
import hx.well.facades.Cache;

class ClearCacheCommand extends AbstractCommand<Void> {
    public override function group():String {
        return "cache";
    }

    public function signature():String {
        return "clear";
    }

    public function description():String {
        return "clears outdated caches";
    }

    public function handle():Void {
        for(cacheInstance in @:privateAccess Cache.cacheInstanceMap) {
            cacheInstance.expireCache();
        }
    }
}

