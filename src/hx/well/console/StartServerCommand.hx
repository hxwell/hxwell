package hx.well.console;
import hx.well.route.Route;
#if (target.threaded)
import sys.thread.Thread;
#end

#if !php
import hx.well.config.InstanceConfig;
#end

import haxe.Exception;

#if php
import hx.well.http.driver.php.PHPInstanceBuilder;
import hx.well.http.driver.php.PHPInstance;
#end

@:build(hx.well.macro.CommandMacro.build())
class StartServerCommand extends AbstractCommand<Bool> {
    public function new() {
        super();
    }

    public function signature():String {
        return "start";
    }

    public function description():String {
        return "start the server";
    }

    public function handle():Bool {
        Route.log();

        #if php
        PHPInstance.builder()
            .build()
            .driver()
            .start();
        #else
        var instances = InstanceConfig.get();
        var primaryInstance = instances.shift();
        #if (target.threaded)
        for(subInstance in instances)
        {

            Thread.create(() -> {
                subInstance.driver().start();
            });
        }
        #else
        if(instances.length > 0)
            throw new Exception("Non-threaded targets do not support multiple instances");

        #end

        primaryInstance.driver().start();

        #if !js
        while (true) {}
        #end
        #end

        return true;
    }
}
