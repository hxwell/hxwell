package hx.well.console;

import hx.well.HxWell.workingDirectory;
import Sys.println;
import hxp.System;

class TestProjectCommand extends BuildProjectCommand {
    public override function signature():String {
        return "test {platform}";
    }

    public override function description():String {
        return "Build the project for the specified platform and run web server.";
    }

    public override function handle():Bool {
        var result:Bool = super.handle();
        if(!result)
            return false;

        var command:String = null;
        var args:Array<String> = [];

        var platform:String = argument("platform");
        switch (platform) {
            case "jvm":
                command = "java";
                args = ["-jar", "hxwell.jar", "start"];
            case "neko":
                command = "neko";
                args = ["hxwell.n", "start"];
            case "cpp":
                command = "./HxWell";
                args = ["start"];
            default:
                println("This platform does not support web server test.");
        }

        if(Sys.getEnv("HAXELIB_RUN") != null) {
            args.push(workingDirectory);
        }

        System.runCommand(exportBasePath, command, args);

        return true;
    }
}