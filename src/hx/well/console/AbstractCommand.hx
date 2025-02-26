package hx.well.console;
import hx.concurrent.executor.Executor.TaskFuture;
using StringTools;


abstract class AbstractCommand {
    private var arguments:Map<String, {value:String, optional:Bool}> = new Map();
    public var future:TaskFuture<Any>;
    public var args(default, set):Array<String> = [];

    private function set_args(args:Array<String>):Array<String> {
        var argIndex = 0;

        for (param => info in arguments) {
            if (argIndex >= args.length) {
                if (!info.optional) {
                    throw 'Missing required parameter: ${param}\nUsage: ${fullCommandKey()}';
                }
                arguments.set(param, {
                    value: null,
                    optional: info.optional
                });
                continue;
            }
            arguments.set(param, {
                value: args[argIndex++],
                optional: info.optional
            });
        }

        return args;
    }

    public function new() {
        parseSignature(); // Constructor'da bir kez parse et
    }

    private function parseSignature():Void {
        var signature = signature();
        var parts = signature.split(" ");
        var command = parts.shift();

        for (part in parts) {
            if (part.startsWith("{") && part.endsWith("}")) {
                var paramName = part.substring(1, part.length - 1);

                // Optional parameter check
                var isOptional = paramName.endsWith("?");
                if (isOptional) {
                    paramName = paramName.substring(0, paramName.length - 1);
                }

                arguments.set(paramName, {
                    value: null,
                    optional: isOptional
                });
            }
        }
    }

    public final function commandKey():String {
        var group:String = group();
        var signature:String = signature();
        var keyIndex:Int = signature.indexOf(" ");
        keyIndex = keyIndex == -1 ? signature.length : keyIndex;

        return (group == null ? "" : '${group}:') + signature.substring(0, keyIndex);
    }

    public final function fullCommandKey():String {
        var group:String = group();
        var signature:String = signature();
        return (group == null ? "" : '${group}:') + signature;
    }

    private function argument(name:String, defaultValue:String = null):String {
        var param = arguments.get(name);
        return param != null && param.value != null ? param.value : defaultValue;
    }

    public abstract function signature():String;
    public abstract function description():String;
    public abstract function handle<T>():T;

    public function group():Null<String> {
        return null;
    }
}
