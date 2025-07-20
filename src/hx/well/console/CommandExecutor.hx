package hx.well.console;

import hx.well.console.AbstractCommand;
import hx.well.database.Connection;
import hx.well.console.ListCommandsCommand;
import hx.well.console.CheckConnectionCommand;
import hx.well.console.StartServerCommand;
import hx.concurrent.executor.Executor.TaskFuture;
import haxe.extern.EitherType;
import haxe.Exception;
using Lambda;
using StringTools;
using hx.well.tools.CommandLineTools;

class CommandExecutor {
    public static var commands:Array<Class<AbstractCommand<Any>>> = [
        #if !cli
        CheckConnectionCommand,
        ClearCacheCommand,
        StartServerCommand,
        #end
        ListCommandsCommand,
    ];

    public static var commandMap:Map<String, Class<AbstractCommand<Any>>> = init();

    public static var defaultCommand:String = "list";

    public static function init():Map<String, Class<AbstractCommand<Any>>> {
        var commandMap = new Map();

        var commandInstances = commands.map(commandClass -> Type.createInstance(commandClass, []));
        for(commandInstance in commandInstances) {
            commandMap.set(commandInstance.commandKey(), Type.getClass(commandInstance));
        }
        return commandMap;
    }

    public static function register(commandClass:Class<AbstractCommand<Any>>):Void {
        var commandInstance = Type.createInstance(commandClass, []);
        commands.push(commandClass);
        commandMap.set(commandInstance.commandKey(), Type.getClass(commandInstance));
    }

    public static function getCommandClass(key:String):Class<AbstractCommand<Any>> {
        return commandMap.get(key);
    }

    public static function executeRaw<T>(args:String, ?future:TaskFuture<T>):Null<T> {
        var parsedArgs = args.parseCommandLine();
        var key:String = parsedArgs.shift();
        key = (key == null ? defaultCommand : key.split(" ")[0]);
        return execute(key, parsedArgs, future);
    }

    public static function execute<T>(command:EitherType<Class<AbstractCommand<T>>, String>, args:Array<String> = null, ?future:TaskFuture<T>):Null<T> {
        args = args == null ? [] : args;
        var value:Null<T> = null;

        command = (command == null ? defaultCommand : (command : String).split(" ")[0]);
        if(command is String) {
            if(commandMap.exists(command)) {
                command = cast commandMap.get(command);
            }
        }

        if (command is Class) {
            try {
                var commandInstance:AbstractCommand<Any> = Type.createInstance(command, []);
                commandInstance.future = future;
                commandInstance.args = args;
                value = commandInstance.handle();
                Connection.free();
            } catch (e:Exception) {
                Connection.free();
                throw e;
            }
        }else{
            trace('Command not found: ${command}');
        }

        return value;
    }
}
