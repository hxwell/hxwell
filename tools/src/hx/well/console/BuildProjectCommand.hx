package hx.well.console;

import sys.FileSystem;
import haxe.io.Path;
import Sys.println;
import haxe.Exception;
import hx.well.HxWell.workingDirectory;
import hx.well.type.FileUtils;
import sys.io.Process;
import hxp.HXML;
using StringTools;

class BuildProjectCommand extends AbstractCommand<Bool> {
    public static var supportedPlatforms:Array<String> =
    [
        "jvm",
        "cpp",
        "hl",
        "php",
        "neko"
    ];

    public var exportBasePath:String;

    public function signature():String {
        return "build {platform}";
    }

    public function description():String {
        return "Build the project for the specified platform.";
    }

    public function handle():Bool {
        var platform:String = argument("platform");
        if (!supportedPlatforms.contains(platform)) {
            println('Unsupported platform: ${platform}. Supported platforms are: ${supportedPlatforms.join(", ")}');
            return false;
        }

        exportBasePath = Path.join([workingDirectory, "Export", platform]);

        // 1. Generate HXML configuration
        var hxml = generateHxmlForPlatform(platform, exportBasePath);

        // 2. Build the project
        var result = hxml.build();
        if (result != 0) {
            throw new Exception('Build failed with exit code: ${result}');
        }

        // 3. Run post-build steps
        runPostBuildSteps(platform, exportBasePath);

        // 4. Copy platform templates
        copyPlatformTemplates(platform, exportBasePath);

        // 5. Copy project templates
        copyProjectTemplates(exportBasePath);

        println('Build successful!');
        return true;
    }

    /**
     * Creates the HXML configuration for the specified platform.
     */
    private function generateHxmlForPlatform(platform:String, exportBasePath:String):HXML {
        var hxml = new HXML();
        hxml.addClassName('--cwd ${workingDirectory}');
        hxml.addClassName("global.hxml");
        hxml.lib("hxwell");

        switch (platform) {
            case "jvm":
                // No JVM Target on HXML, Define Manually
                hxml.lib("hxjava");
                hxml.addClassName('--jvm ${exportBasePath}/hxwell.jar');

                JVMRecursivelyAddLibrary(Path.join([workingDirectory, "java-lib"]), hxml);
            case "cpp":
                hxml.lib("hxcpp");
                hxml.cpp = '${exportBasePath}/out';
            case "hl":
                hxml.hl = '${exportBasePath}/hxwell.hl';
            case "php":
                hxml.php = exportBasePath;
            case "neko":
                hxml.neko = '${exportBasePath}/hxwell.n';
        }

        return hxml;
    }

    /**
     * Recursively scans a given directory and its subdirectories for `.jar` files.
     * Each `.jar` file found is added as a Java library (`-java-lib`) to the
     * provided HXML configuration object.
     *
     * @param directoryPath The absolute or relative path to the directory to start scanning.
     * @param hxml The HXML configuration object to which the `.jar` file paths will be added.
     */
    private function JVMRecursivelyAddLibrary(directoryPath:String, hxml:HXML):Void {
        if (!FileSystem.exists(directoryPath) || !FileSystem.isDirectory(directoryPath)) {
            return;
        }

        for (entryName in FileSystem.readDirectory(directoryPath)) {
            var fullEntryPath = Path.join([directoryPath, entryName]);

            if (FileSystem.isDirectory(fullEntryPath)) {
                JVMRecursivelyAddLibrary(fullEntryPath, hxml);
            } else if (entryName.endsWith(".jar")) {
                hxml.javaLib(fullEntryPath);
            }
        }
    }

    /**
     * Executes platform-specific tasks after the build is complete.
     */
    private function runPostBuildSteps(platform:String, exportBasePath:String):Void {
        switch (platform) {
            case "php":
                // For PHP, rename the generated index.php to the boot file.
                var srcFilePath = Path.join([exportBasePath, 'index.php']);
                var destFilePath = Path.join([exportBasePath, 'hxwell.boot.php']);

                if (FileSystem.exists(srcFilePath)) {
                    if (FileSystem.exists(destFilePath)) {
                        FileSystem.deleteFile(destFilePath);
                    }
                    FileSystem.rename(srcFilePath, destFilePath);
                }
        }
    }

    /**
     * Copies the required platform template files.
     */
    private function copyPlatformTemplates(platform:String, exportBasePath:String):Void {
        try {
            var haxelibPath = getHaxelibPath("hxwell");
            var exportTemplatePath = Path.join([haxelibPath, 'template', 'Export', platform]);

            if (FileSystem.exists(exportTemplatePath)) {
                FileUtils.copyRecursive(exportTemplatePath, exportBasePath);
            }
        } catch (e:Exception) {
            println('Warning: Could not copy templates. Reason: ${e.message}');
        }
    }

    /**
     * Copies the project template files to the export directory.
     */
    private function copyProjectTemplates(exportBasePath:String):Void {
        try {
            var directories:Array<String> = ["public"];

            for (dir in directories) {
                var templatePath = Path.join([workingDirectory, dir]);
                if (FileSystem.exists(templatePath)) {
                    var destPath = Path.join([exportBasePath, dir]);
                    FileUtils.copyRecursive(templatePath, destPath);
                } else {
                    throw new Exception('Template directory "${templatePath}" does not exist.');
                }
            }
        } catch (e:Exception) {
            println('Warning: Could not copy project templates. Reason: ${e.message}');
        }
    }

    /**
     * Retrieves the filesystem path for a given haxelib library.
     * @throws Exception if the haxelib command fails or the library path is not found.
     */
    private function getHaxelibPath(libName:String):String {
        var process = new Process("haxelib", ["libpath", libName]);

        if (process.exitCode() != 0) {
            throw new Exception('Haxelib process failed. Error: ${process.stderr.readAll().toString()}');
        }

        var haxelibPath = process.stdout.readLine();
        if (haxelibPath == null || haxelibPath.trim() == "") {
            throw new Exception('Could not find path for haxelib library: "${libName}". Is it installed?');
        }

        return haxelibPath.trim();
    }
}