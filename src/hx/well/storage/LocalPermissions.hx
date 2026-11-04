package hx.well.storage;

/** Apply real filesystem permissions; visibility is never an in-memory label. */
#if cpp
@:cppInclude("sys/stat.h")
#end
class LocalPermissions {
    public static function set(path:String, visibility:String, directory:Bool):Void {
        StoragePath.visibility(visibility);
        var mode = directory ? (visibility == "public" ? 493 : 448) : (visibility == "public" ? 420 : 384);
        if (Sys.systemName() == "Windows")
            throw new haxe.Exception("Local storage visibility requires POSIX filesystem permissions.");
        #if java
        java.nio.file.Files.setPosixFilePermissions(java.nio.file.Paths.get(path),
            java.nio.file.attribute.PosixFilePermissions.fromString(directory
                ? (visibility == "public" ? "rwxr-xr-x" : "rwx------")
                : (visibility == "public" ? "rw-r--r--" : "rw-------")));
        #elseif js
        js.node.Fs.chmodSync(path, mode);
        #elseif php
        if (!php.Syntax.code("chmod({0}, {1})", path, mode)) throw new haxe.Exception("Unable to set storage permissions.");
        #elseif (cpp && !windows)
        if (untyped __cpp__("::chmod({0}.utf8_str(), {1})", path, mode) != 0)
            throw new haxe.Exception("Unable to set storage permissions.");
        #elseif cpp
        throw new haxe.Exception("Local storage visibility requires POSIX filesystem permissions.");
        #else
        // Haxe's Neko/HashLink/eval standard APIs do not expose chmod. Arguments
        // are passed separately, never interpolated into a shell command.
        var octal = directory ? (visibility == "public" ? "755" : "700") : (visibility == "public" ? "644" : "600");
        if (Sys.command("chmod", [octal, path]) != 0)
            throw new haxe.Exception("Unable to set storage permissions.");
        #end
    }
}
