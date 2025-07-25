package hx.well.provider;
import hx.well.console.BuildProjectCommand;
import hx.well.console.HostProjectCommand;
import hx.well.console.CommandExecutor;
import hx.well.console.CreateProjectCommand;
import hx.well.console.TestProjectCommand;
class CLIProvider extends AbstractProvider {
    public function boot():Void {
        // Register the commands
        CommandExecutor.register(CreateProjectCommand);
        CommandExecutor.register(BuildProjectCommand);
        CommandExecutor.register(TestProjectCommand);
        CommandExecutor.register(HostProjectCommand);
    }
}