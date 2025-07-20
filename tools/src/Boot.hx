package;
import hx.well.boot.BaseBoot;
import hx.well.console.CommandExecutor;
import hx.well.server.instance.IInstance;
import hx.well.console.CreateProjectCommand;

class Boot extends BaseBoot {
    public function boot():Void {
        // Register the commands
        CommandExecutor.register(CreateProjectCommand);
    }

    public function instances():Array<IInstance> {
        return [];
    }
}