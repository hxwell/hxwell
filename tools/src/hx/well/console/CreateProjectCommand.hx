package hx.well.console;

import sys.FileSystem;
import haxe.io.Path;
import Sys.println;
import haxe.Exception;
import hx.well.HxWell.workingDirectory;
import hx.well.type.FileUtils;
import sys.io.Process;

class CreateProjectCommand extends AbstractCommand<Bool> {
    public function signature():String {
        return "new {folder}";
    }

    public function description():String {
        return "Create a new project in the specified folder.";
    }

    public function handle():Bool {
        var folder:String = argument("folder");

        var targetDirectory:String = Path.join([workingDirectory, folder]);
        if(FileSystem.exists(targetDirectory))
        {
            println('${folder} already exists. Please choose a different name or remove the existing folder.');
            return false;
        }

        try {
            FileSystem.createDirectory(targetDirectory);
        } catch (e:Exception) {
            println('Failed to create directory: ${e.message}');
            return false;
        }

        // Copy default project files from the template/project directory
        var process = new Process("haxelib", ["libpath", "hxwell"]);
        var haxelibPath = process.stdout.readLine();
        var templatePath:String = Path.join([haxelibPath, "template", "project"]);

        if (!FileSystem.exists(templatePath)) {
            println('Template path does not exist: ${templatePath}');
            return false;
        }

        // Copy files from the template directory to the target directory
        try {
            FileUtils.copyRecursive(templatePath, targetDirectory);
        } catch (e:Exception) {
            println('Failed to copy template files: ${e.message}');
            return false;
        }

        println('Project created successfully in ${targetDirectory}');
        return true;
    }
}