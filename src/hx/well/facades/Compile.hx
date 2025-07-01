package hx.well.facades;

@:build(hx.well.macro.CompileDetailsMacro.build())
class Compile {
    public static var defines:Map<String, String>;
    public static var operatingSystem:String;
    public static var gitCommit:String;
    public static var date:String;

    public static function all():Map<String, Dynamic> {
        var all:Map<String, Dynamic> = new Map<String, Dynamic>();
        all.set("defines", defines);
        all.set("operatingSystem", operatingSystem);
        all.set("gitCommit", gitCommit);
        all.set("date", date);
        return all;
    }

}