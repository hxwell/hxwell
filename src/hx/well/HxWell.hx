package hx.well;
import hx.well.facades.Environment;
import hx.well.console.CommandExecutor;
import hx.well.http.HttpHandler;
import hx.well.middleware.AbstractMiddleware;
import haxe.Exception;
import haxe.CallStack;
import Sys.println;
import Sys.print;
import hx.well.config.ProviderConfig;

class HxWell {
    public static var handlers:Array<HttpHandler> = [];
    public static var middlewares:Array<Class<AbstractMiddleware>> = hx.well.config.MiddlewareConfig.get();
    public static var workingDirectory:String = Sys.getCwd();

    public static function main() {
        #if php
        // Disable trace logging for php
        haxe.Log.trace = function(v, ?infos) {

        };
        #end

        // Application Level Error Handling
        try {
            #if !cli
            Environment.load();
            #end

            for(providerClass in ProviderConfig.get())
            {
                var provider = Type.createInstance(providerClass, []);
                provider.boot();
            }

            #if php
            if(!php.Lib.isCli())
            {
                CommandExecutor.execute("start");
                return;
            }
            #end

            #if disable_cli
            CommandExecutor.execute("start");
            #else
            var args = Sys.args();
            if(Sys.getEnv("HAXELIB_RUN") != null) {
                workingDirectory = args.pop(); // Remove the program path
            }

            var command = args.shift();
            CommandExecutor.execute(command, args);
            #end
        } catch (e:Exception) {
            print(e);
            println(CallStack.toString(e.stack));
            Sys.exit(1);
        }
    }
}