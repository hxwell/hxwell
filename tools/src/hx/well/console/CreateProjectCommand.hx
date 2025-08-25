package hx.well.console;

import hx.well.HxWell.workingDirectory;
import hx.well.type.FileUtils;
import Sys.println;
import sys.FileSystem;
import sys.io.Process;
import sys.io.File;
import haxe.io.Path;
import haxe.Exception;
using StringTools;

class CreateProjectCommand extends AbstractCommand<Bool> {
    private static var APP_NAME:String = "HxWell";

    public function signature():String {
        return "new {folder}";
    }

    public function description():String {
        return "Create a new project in the specified folder.";
    }

    public function handle():Bool {
        var folder:String = argument("folder");

        var targetDirectory:String = Path.normalize(Path.join([workingDirectory, folder]));
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

        APP_NAME = targetDirectory.substr(targetDirectory.lastIndexOf("/") + 1);

        // Copy default project files from the template/project directory
        var process = new Process("haxelib", ["libpath", "hxwell"]);
        var haxelibPath = process.stdout.readLine();
        process.close();
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

        // 6. Create project crypto key
        createProjectCryptoKey(targetDirectory);

        println('Project created successfully in ${targetDirectory}');
        return true;
    }

    private function createProjectCryptoKey(targetDirectory:String):Void {
        var cryptoKey:String = CommandExecutor.execute("generate:key");
        if(cryptoKey == null)
            throw new Exception('Failed to generate crypto key');

        // Read .env file from exportBasePath if exists, otherwise throw error
        var envFilePath = Path.join([targetDirectory, ".env"]);
        if (!FileSystem.exists(envFilePath))
            throw new Exception('Could not find .env file at path: ${envFilePath}');

        var envContent:String = File.getContent(envFilePath);
        // TODO: Improve this to use regex to find APP_KEY line and replace it
        envContent = setRawEnvContent(envContent, "APP_KEY", cryptoKey);
        envContent = setRawEnvContent(envContent, "APP_NAME", APP_NAME);

        var file = File.write(envFilePath, true);
        file.writeString(envContent);
        file.close();
    }

    private function setRawEnvContent(content:String, key:String, value:String):String {
        if(!content.contains('${key}=\r\n'))
        {
            Sys.println('Warning: ${key} line not found in .env file. Add it with \'haxelib run hxwell generate:key\'');
            return content;
        }

        content = content.replace('${key}=\r\n', '${key}=${value}\r\n');
        return content;
    }
}