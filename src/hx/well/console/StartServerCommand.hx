package hx.well.console;
import hx.well.route.Route;
import sys.thread.Thread;

@:build(hx.well.macro.CommandMacro.build())
class StartServerCommand extends AbstractCommand<Void> {
    public function new() {
        super();
    }

    public function signature():String {
        return "start";
    }

    public function description():String {
        return "start the server";
    }

    public function handle():Void {
        Route.log();

        var bootInstance = HxWell.bootInstance;
        var instances = bootInstance.instances().copy();
        var primaryInstance = instances.shift();
        for(subInstance in instances)
        {
            Thread.create(() -> {
                subInstance.driver().start();
            });
        }

        primaryInstance.driver().start();

        while (true) {}
    }
}
