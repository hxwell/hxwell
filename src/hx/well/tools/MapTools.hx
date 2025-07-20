package hx.well.tools;

class MapTools {
    public static function concat<K, V>(map:Map<K, V>, concatMap:Map<K, V>, overrideEntries:Bool = true) {
        var map = map.copy();
        for(keyValueIterator in concatMap.keyValueIterator())
        {
            if(overrideEntries) {
                map.set(keyValueIterator.key, keyValueIterator.value);
            }else{
                if(!map.exists(keyValueIterator.key))
                    map.set(keyValueIterator.key, keyValueIterator.value);
            }
        }
        return map;
    }

    public static function toDynamic<V>(map:Map<String, V>):#if php Dynamic #else Map<String, Dynamic> #end {
        var dynamicObject:Dynamic = {};
        for(keyValue in map.keyValueIterator()) {
            Reflect.setField(dynamicObject, keyValue.key, keyValue.value);
        }
        return dynamicObject;
    }
}