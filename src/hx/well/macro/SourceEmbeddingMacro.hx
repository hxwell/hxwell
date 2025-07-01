package hx.well.macro;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.macro.Compiler;
using StringTools;

class SourceEmbeddingMacro {
    public static function build() {
        #if include_source
        Context.onAfterInitMacros(() -> {
            for(classPath in Context.getClassPath()) {
                addResources(classPath, classPath);
            }
        });
        #end
    }

    #if include_source
    private static function addResources(path:String, rootPath:String):Void {

        if(!FileSystem.exists(path))
            return;

        // Recursively add resources from the specified path
        var files = FileSystem.readDirectory(path);
        for (file in files) {
            var fullPath = path + "/" + file;
            fullPath = Path.normalize(fullPath);

            var keyPath = fullPath;
            if(haxe.macro.Context.defined("cpp"))
            {
                var haxePath = Sys.getEnv("HAXEPATH");
                haxePath = haxePath != null ? Path.normalize(haxePath + "/std") : null;

                if (haxePath == null || !fullPath.startsWith(haxePath)) {
                    keyPath = fullPath.substr(rootPath.length);
                }
            }

            if (FileSystem.isDirectory(fullPath)) {
                addResources(fullPath, rootPath);
            } else {

                // Only add .hx files
                if(!fullPath.endsWith(".hx"))
                    continue;

                haxe.macro.Context.addResource('source/${keyPath}', File.getBytes(fullPath));
            }
        }
    }
    #end
}
