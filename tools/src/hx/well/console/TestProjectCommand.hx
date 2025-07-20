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

        var platform:String = argument("platform");
        switch (platform) {
            case "jvm":
                System.runCommand(exportBasePath, "java", ["-jar", "hxwell.jar", "start", workingDirectory]);
            default:
                println("This platform does not support web server test.");
        }
        return true;
    }
}