package hx.well.storage;

/** Disk options use Haxe identifiers for Laravel's `throw` and `read-only` keys. */
typedef StorageDiskConfig = {
    var driver:String;
    @:optional var root:String;
    @:optional var url:String;
    @:optional var visibility:String;
    @:optional var directory_visibility:String;
    @:optional var throw_errors:Bool;
    @:optional var read_only:Bool;
    @:optional var disk:String;
    @:optional var prefix:String;
    /** Driver-specific settings for factories registered with Storage.extend(). */
    @:optional var options:Dynamic;
}
