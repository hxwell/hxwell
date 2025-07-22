package;
import hx.well.boot.BaseBoot;
import hx.well.console.CommandExecutor;
import hx.well.server.instance.IInstance;
import hx.well.console.CreateProjectCommand;
import hx.well.console.BuildProjectCommand;
import hx.well.console.TestProjectCommand;
import hx.well.console.HostProjectCommand;

class Boot extends BaseBoot {
    public function boot():Void {
        // Register the commands
        CommandExecutor.register(CreateProjectCommand);
        CommandExecutor.register(BuildProjectCommand);
        CommandExecutor.register(TestProjectCommand);
        CommandExecutor.register(HostProjectCommand);
    }

    public function instances():Array<IInstance> {
        return [];
    }
}