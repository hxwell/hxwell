package hx.well;

import hx.well.facades.Environment;
import hx.well.boot.BaseBoot;
import hx.well.route.Route;
import hx.well.http.AbstractResponse;
import hx.well.console.CommandExecutor;
import hx.well.facades.Cache;

class HxWell {
    public static var bootInstance:BaseBoot;

    public static function main() {
        Environment.load();

        bootInstance = new Boot();
        bootInstance.boot();


        #if disable_cli
        CommandExecutor.execute("start");
        #else
        var args = Sys.args();
        var command = args.shift();
        CommandExecutor.execute(command, args);
        #end
    }
}