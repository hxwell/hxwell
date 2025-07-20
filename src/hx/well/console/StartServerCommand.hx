package hx.well.console;
import hx.well.route.Route;
#if !php
import sys.thread.Thread;
#end

#if php
import hx.well.http.driver.php.PHPInstanceBuilder;
import hx.well.http.driver.php.PHPInstance;
#end

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

        #if php
        PHPInstance.builder()
            .build()
            .driver()
            .start();
        #else
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
        #end
    }
}
