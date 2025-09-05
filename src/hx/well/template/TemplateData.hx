package hx.well.template;
import haxe.Template;
import haxe.ds.StringMap;

@:build(hx.well.macro.TemplateMacro.build())
class TemplateData {
    public static var data:StringMap<Template> = new StringMap();

    public function new() {
    }
}
