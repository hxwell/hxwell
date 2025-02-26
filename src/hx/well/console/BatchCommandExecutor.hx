package hx.well.console;
class BatchCommandExecutor {
    private var commands:Array<Class<AbstractCommand>>  = [];

    public function new() {

    }

    public function addCommand(commandClass:Class<AbstractCommand>):Void {
        commands.push(commandClass);
    }

    public function execute():Void {
        while (commands.length > 0) {
            var command:Class<AbstractCommand> = commands.shift();
            try {
                Type.createInstance(command, []).handle();
            } catch (e:Dynamic) {
                trace(e);
            }
        }
    }
}
