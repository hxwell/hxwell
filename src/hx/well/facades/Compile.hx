package hx.well.facades;

using hx.well.tools.MapTools;

@:build(hx.well.macro.CompileDetailsMacro.build())
class Compile {
    public static var defines:Map<String, String>;
    public static var operatingSystem:String;
    public static var gitCommit:String;
    public static var date:String;

    public static function all():#if php Dynamic #else Map<String, Dynamic> #end {
        var all:Map<String, Dynamic> = new Map<String, Dynamic>();
        all.set("defines", defines #if php .toDynamic() #end);
        all.set("operatingSystem", operatingSystem);
        all.set("gitCommit", gitCommit);
        all.set("date", date);
        return all#if php .toDynamic() #end;
    }

}