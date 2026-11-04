package hx.well.storage;

class StorageException extends haxe.Exception {
    public var operation(default, null):String;
    public var path(default, null):String;

    public function new(operation:String, path:String, ?previous:haxe.Exception) {
        super('Storage ${operation} failed for "${path}".', previous);
        this.operation = operation;
        this.path = path;
    }
}
