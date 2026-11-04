package hx.well.storage;

class StoragePath {
    public static function normalize(path:String):String {
        if (path == null || ~/[\x00-\x1f\x7f:]/.match(path))
            throw new InvalidStoragePath(path);
        var result:Array<String> = [];
        for (part in StringTools.replace(path, "\\", "/").split("/")) {
            switch (part) {
                case "", ".":
                case "..":
                    if (result.length == 0) throw new InvalidStoragePath(path);
                    result.pop();
                default: result.push(part);
            }
        }
        return result.join("/");
    }

    public static function file(path:String):String {
        var normalized = normalize(path);
        if (normalized == "") throw new InvalidStoragePath(path);
        return normalized;
    }

    public static function visibility(value:String):String {
        if (value != "public" && value != "private")
            throw new haxe.Exception('Unknown storage visibility "${value}".');
        return value;
    }
}
