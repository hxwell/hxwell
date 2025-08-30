package hx.well;
import hx.well.facades.Environment;
import hx.well.console.CommandExecutor;
import hx.well.http.HttpHandler;
import hx.well.middleware.AbstractMiddleware;
import haxe.Exception;
import haxe.CallStack;
import Sys.println;
import Sys.print;
import hx.well.facades.Config;
import hx.well.provider.AbstractProvider;
import hx.well.config.ConfigData;
import haxe.macro.Compiler;
import haxe.ds.StringMap;
import hx.well.database.Connection;

class HxWell {
    public static var handlers:Array<HttpHandler> = [];
    public static var middlewares:Array<Class<AbstractMiddleware>> = Config.get("middleware").get();
    public static var workingDirectory:String = Sys.getCwd();

    public static function  __init__() {
        #if disable_env
        Environment.reset();
        #else
        Environment.load(Compiler.getDefine("env_file"));
        #end
        ConfigData.init();
    }

    public static function main() {
        #if php
        // Disable trace logging for php
        haxe.Log.trace = function(v, ?infos) {

        };
        #end

        // TODO: move database code to prevent code spagetti, also make more flexible
        var databaseConnections:StringMap<Dynamic> = Config.get("database.connections");
        for(databaseConnectionKey in databaseConnections.keys()) {
            var databaseConnectionConfig = databaseConnections.get(databaseConnectionKey);
            switch (databaseConnectionConfig.driver) {
                case "sqlite":
                    Connection.create(databaseConnectionKey, {path: databaseConnectionConfig.path});
                case "mysql":
                    Connection.create(databaseConnectionKey, {host: databaseConnectionConfig.host, port: databaseConnectionConfig.port, username: databaseConnectionConfig.username, password: databaseConnectionConfig.password});
                case "none":
                default:
                    throw databaseConnectionConfig.driver + " driver not found.";
            }
        }

        // Application Level Error Handling
        try {
            var providers:Array<Class<AbstractProvider>> = Config.get("provider").get();
            for(providerClass in providers)
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