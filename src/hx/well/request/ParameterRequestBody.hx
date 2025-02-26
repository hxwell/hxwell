package hx.well.request;
import haxe.io.Bytes;
import haxe.Json;
using StringTools;

class ParameterRequestBody extends AbstractRequestBody {
    private var data:Map<String, String> = new Map<String, String>();

    public function new(bodyBytes:Bytes) {
        super(bodyBytes);

        var pairs = bodyBytes.toString().split("&");
        for (pair in pairs) {
            var parts = pair.split("=");
            if (parts.length == 2) {
                data.set(parts[0].urlDecode(), parts[1].urlDecode());
            }
        }
    }

    public function map():Map<String, String> {
        return data;
    }

    public function keys():Array<String> {
        return [for (key in data.keys()) key];
    }

    public function get(key:String):Null<Dynamic> {
        return data.get(key);
    }

    public function exists(key:String):Bool {
        return data.exists(key);
    }
}
