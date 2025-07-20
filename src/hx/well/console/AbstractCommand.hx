package hx.well.console;
import hx.concurrent.executor.Executor.TaskFuture;
using StringTools;

abstract class AbstractCommand<T> {
    private var argumentsMap:Map<String, {value:String, optional:Bool}> = new Map();
    private var argumentOrder:Array<{name:String, optional:Bool}> = [];

    public var future:TaskFuture<T>;
    public var args(default, set):Array<String> = [];

    private function set_args(raw:Array<String>):Array<String> {
        var args = parseArgs(raw);
        var argIndex = 0;

        for (arg in argumentOrder) {
            var name = arg.name;
            var info = arg;

            if (argIndex >= args.length) {
                if (!info.optional) {
                    throw 'Missing required parameter: $name\nUsage: ${fullCommandKey()}';
                }
                argumentsMap.set(name, {
                    value: null,
                    optional: info.optional
                });
                continue;
            }

            argumentsMap.set(name, {
                value: args[argIndex++],
                optional: info.optional
            });
        }

        return raw;
    }

    public function new() {
        parseSignature();
    }

    private function parseSignature():Void {
        var signature = signature();
        var parts = signature.split(" ");
        var command = parts.shift();

        for (part in parts) {
            if (part.startsWith("{") && part.endsWith("}")) {
                var paramName = part.substring(1, part.length - 1);
                var isOptional = paramName.endsWith("?");
                if (isOptional) {
                    paramName = paramName.substring(0, paramName.length - 1);
                }

                argumentOrder.push({ name: paramName, optional: isOptional });
                argumentsMap.set(paramName, {
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
        var group:Null<String> = group();
        var signature:String = signature();
        return (group == null ? "" : '$group:') + signature;
    }

    private function argument(name:String, defaultValue:String = null):String {
        var param = argumentsMap.get(name);
        return param != null && param.value != null ? param.value : defaultValue;
    }

    public abstract function signature():String;
    public abstract function description():String;
    public abstract function handle():T;

    public function group():Null<String> {
        return null;
    }

    private function parseArgs(input:Array<String>):Array<String> {
        var result:Array<String> = [];
        var buffer = "";
        var inQuotes = false;

        for (part in input) {
            if (inQuotes) {
                buffer += " " + part;
                if (part.endsWith("\"") && !part.endsWith("\\\"")) {
                    inQuotes = false;
                    result.push(buffer.substr(1, buffer.length - 2).replace("\\\"", "\""));
                    buffer = "";
                }
            } else if (part.startsWith("\"")) {
                if (part.endsWith("\"") && part.length > 1) {
                    result.push(part.substr(1, part.length - 2).replace("\\\"", "\""));
                } else {
                    buffer = part;
                    inQuotes = true;
                }
            } else {
                result.push(part);
            }
        }

        if (inQuotes) {
            throw "Unclosed quoted argument in input: " + input.join(" ");
        }

        return result;
    }
}