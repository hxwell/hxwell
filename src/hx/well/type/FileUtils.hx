package hx.well.type;
import sys.io.File;
import sys.FileSystem;

class FileUtils {
    public static function copyRecursive(src:String, dest:String):Void {
        if (!FileSystem.exists(src) || !FileSystem.isDirectory(src)) {
            throw 'Source folder not found: $src';
        }

        // Create destination folder if it doesn't exist
        if (!FileSystem.exists(dest)) {
            FileSystem.createDirectory(dest);
        }

        // Read all entries in the source directory
        for (entry in FileSystem.readDirectory(src)) {
            var srcPath = src + "/" + entry;
            var destPath = dest + "/" + entry;

            if (FileSystem.isDirectory(srcPath)) {
                // Copy directory recursively
                copyRecursive(srcPath, destPath);
            } else {
                // Copy file
                var input = File.read(srcPath, true);
                var output = File.write(destPath, true);
                output.writeInput(input);
                input.close();
                output.close();
            }
        }
    }
}
