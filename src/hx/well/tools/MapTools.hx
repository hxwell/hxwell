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
}