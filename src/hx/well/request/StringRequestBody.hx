package hx.well.request;
import haxe.io.Bytes;
class StringRequestBody extends AbstractRequestBody {
    private var data:Map<String, String> = new Map<String, Dynamic>();

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
}
