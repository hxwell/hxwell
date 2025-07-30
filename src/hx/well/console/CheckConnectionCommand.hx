package hx.well.console;
import hx.well.database.Connection;
import haxe.CallStack;
import haxe.Exception;

class CheckConnectionCommand extends AbstractCommand<Bool> {
    public override function group():String {
        return "connection";
    }

    public function signature():String {
        return "check {key?}";
    }

    public function description():String {
        return "Tests defined database connections.";
    }

    public function handle():Bool {
        var connectionKeys = Connection.connectionKeys();
        if (connectionKeys.length == 0) {
            Sys.println("Connection source(s) not found.");
            return false;
        }

        var connectionKeyArg:String = argument("key");
        if (connectionKeyArg != null) {
            connectionKeys = connectionKeys.filter(connectionKey -> connectionKey == connectionKeyArg);
            if (connectionKeys.length == 0) {
                Sys.println('${connectionKeyArg} connection source not found.');
                return false;
            }
        }

        for (connectionKey in connectionKeys) {
            try {
                var connection = Connection.get(connectionKey);
                connection.request("SELECT 1");
            } catch (e:Exception) {
                trace('${connectionKey} connection failed\n' + CallStack.toString(e.stack));
                continue;
            }

            Sys.println('${connectionKey} connection success');
        }

        return true;
    }
}
