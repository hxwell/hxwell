package hx.well.console;
import hx.concurrent.executor.Executor.TaskFuture;
using StringTools;

abstract class AbstractCommand<T> {
    private var argumentsMap:Map<String, {value:String, optional:Bool}> = new Map();
    private var argumentOrder:Array<{name:String, optional:Bool}> = [];

    private var optionsMap:Map<String, String> = new Map();

    public var future:TaskFuture<T>;
    public var args(default, set):Array<String> = [];

    private function set_args(raw:Array<String>):Array<String> {
        optionsMap = new Map();
        for (argInfo in argumentOrder) {
            argumentsMap.set(argInfo.name, { value: null, optional: argInfo.optional });
        }

        var processedInput = parseArgs(raw);

        var positionalArgs:Array<String> = [];

        for (part in processedInput) {
            if (part.startsWith("-")) {
                var cleanPart = part;
                while (cleanPart.startsWith("-")) {
                    cleanPart = cleanPart.substring(1);
                }

                var eqIndex = cleanPart.indexOf("=");
                if (eqIndex != -1) {
                    var key = cleanPart.substring(0, eqIndex);
                    var value = cleanPart.substring(eqIndex + 1);
                    optionsMap.set(key, value);
                } else {
                    optionsMap.set(cleanPart, "");
                }
            } else {
                positionalArgs.push(part);
            }
        }

        var argIndex = 0;
        for (argInfo in argumentOrder) {
            var name = argInfo.name;

            if (argIndex >= positionalArgs.length) {
                if (!argInfo.optional) {
                    throw 'Missing required parameter: $name\nUsage: ${fullCommandKey()}';
                }
                continue;
            }

            argumentsMap.set(name, {
                value: positionalArgs[argIndex++],
                optional: argInfo.optional
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

    private function hasArgument(name:String):Bool {
        return argumentsMap.exists(name);
    }

    private function argument(name:String, defaultValue:String = null):String {
        var param = argumentsMap.get(name);
        return param != null && param.value != null ? param.value : defaultValue;
    }

    public function hasOption(name:String):Bool {
        return optionsMap.exists(name);
    }

    public function getOption(name:String, defaultValue:String = null):String {
        return optionsMap.get(name) ?? defaultValue;
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