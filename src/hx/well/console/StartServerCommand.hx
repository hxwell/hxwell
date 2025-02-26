package hx.well.console;
import hx.well.route.Route;

@:build(hx.well.macro.CommandMacro.build())
class StartServerCommand extends AbstractCommand {
    public function new() {
        super();
    }

    public function signature():String {
        return "start";
    }

    public function description():String {
        return "start the server";
    }

    public function handle<T>():T {
        Route.log();

        var bootInstance = HxWell.bootInstance;
        var servers = bootInstance.servers().copy();
        var primaryServer = servers.shift();
        for(config in servers)
        {
            var secondaryServer:WebServer = new WebServer(config);
            secondaryServer.startMultiThread();
        }

        var webServer:WebServer = new WebServer(primaryServer);
        webServer.start();

        return null;
    }
}
