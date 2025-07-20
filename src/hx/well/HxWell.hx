package hx.well;
import hx.well.facades.Environment;
import hx.well.boot.BaseBoot;
import hx.well.console.CommandExecutor;
import hx.well.http.HttpHandler;
import hx.well.middleware.AbstractMiddleware;
import haxe.Exception;
import haxe.CallStack;
import Sys.println;
import Sys.print;
import sys.io.Process;

class HxWell {
    public static var bootInstance:BaseBoot;
    public static var handlers:Array<HttpHandler> = [];
    public static var middlewares:Array<Class<AbstractMiddleware>> = hx.well.config.MiddlewareConfig.get();
    public static var workingDirectory:String = Sys.getCwd();
    public static var haxelibPath:String;

    public static function main() {
        var process = new Process("haxelib", ["libpath", "hxwell"]);
        haxelibPath = process.stdout.readLine();

        // Application Level Error Handling
        try {
            #if !cli
            Environment.load();
            #end

            bootInstance = new Boot();
            bootInstance.boot();

            #if disable_cli
            CommandExecutor.execute("start");
            #else
            var args = Sys.args();
            if(haxelibPath == workingDirectory) {
                workingDirectory = args.pop(); // Remove the program path
            }

            var command = args.shift();
            CommandExecutor.execute(command, args);
            #end
        } catch (e:Exception) {
            print(e);
            println(CallStack.toString(e.stack));
        }
    }
}