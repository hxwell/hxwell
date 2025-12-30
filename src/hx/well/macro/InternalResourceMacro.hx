package hx.well.macro;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using StringTools;

class InternalResourceMacro {
    public static function build() {
        // haxelib libpath
        var process = new Process("haxelib", ["libpath", "hxwell"]);
        var path = '${process.stdout.readLine()}/resources';
        addResources(path, path);
    }

    private static function addResources(path:String, rootPath:String):Void {
        // Recursively add resources from the specified path
        var files = FileSystem.readDirectory(path);
        for (file in files) {
            var fullPath = path + "/" + file;
            if (FileSystem.isDirectory(fullPath)) {
                addResources(fullPath, rootPath);
            } else {
                // Add the file as a resource
                var simplePath = 'internal/${fullPath.substring(rootPath.length + 1)}';
                haxe.macro.Context.addResource(simplePath, File.getBytes(fullPath));
            }
        }
    }
}
