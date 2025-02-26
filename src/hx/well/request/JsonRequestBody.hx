package hx.well.request;
import haxe.io.Bytes;
import haxe.Json;

class JsonRequestBody extends AbstractRequestBody {
    private var data:Dynamic;
    private var cache:Map<String, Dynamic> = new Map();
    private var blacklist:Array<String> = new Array();

    public function new(bodyBytes:Bytes) {
        super(bodyBytes);
        this.data = Json.parse(bodyBytes.toString());
    }

    public function get(key:String):Null<Dynamic> {
        if (blacklist.contains(key)) return null;
        if (cache.exists(key)) return cache.get(key);

        var value:Dynamic = this.data;
        var keyParts:Array<String> = key.split(".");
        for (keyPart in keyParts) {
            if (value is Array) {
                var index:Int = Std.parseInt(keyPart);

                // That's not index!
                // Regex is better but slower :(
                if(Std.string(index) != keyPart)
                {
                    value = null;
                    break;
                }

                value = (value : Array<Any>)[index];
            } else {
                value = Reflect.field(value, keyPart);
            }

            if (value == null) {
                blacklist.push(key);
                return null;
            }
        }

        cache.set(key, value);
        return value;
    }

    public function keys():Array<String> {
        return [];
    }

    public function exists(key:String):Bool {
        return get(key) != null;
    }
}
