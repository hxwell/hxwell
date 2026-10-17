package hx.well.template;
import haxe.Template;
import haxe.ds.StringMap;

@:build(hx.well.macro.TemplateMacro.build())
class TemplateData {
    public static var data:StringMap<String> = new StringMap();

    #if target.threaded
    private static var parseMutex = new sys.thread.Mutex();
    #end

    public static function create(name:String):Null<Template> {
        var source = data.get(name);
        if(source == null)
            return null;

        // Template has mutable render state AND shared regexes in its parser.
        // Serialize parsing only; each request renders its own instance.
        #if target.threaded
        parseMutex.acquire();
        try {
            var template = new Template(source);
            parseMutex.release();
            return template;
        } catch (e:Dynamic) {
            parseMutex.release();
            throw e;
        }
        #else
        return new Template(source);
        #end
    }

    public function new() {
    }
}
