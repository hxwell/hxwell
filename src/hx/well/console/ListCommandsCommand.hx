package hx.well.console;
import hx.well.console.CommandExecutor;

class ListCommandsCommand extends AbstractCommand<Void> {
    public function signature():String {
        return "list {group?}";
    }

    public function description():String {
        return "lists available commands";
    }

    public function handle():Void {
        var group = argument("group");

        var commands = CommandExecutor.commands.map(command -> Type.createInstance(command, []));

        var groups:Array<String> = [];
        if(group == null) {
            for(command in commands) {
                var group = command.group();

                if(!groups.contains(group))
                    groups.push(group);
            }
        }else{
            groups.push(group);
        }

        groups.sort((groupValue1, groupValue2) -> groupValue2 == null ? 1 : 0);

        Sys.println('Commands\n');
        for (group in groups) {
            var commands = commands.filter(command -> command.group() == group);
            if (group != null) Sys.println('[${group}]');
            for (command in commands) {
                var group:String = command.group();
                var signature:String = command.signature();

                Sys.println('${(group == null ? "" : '${group}:') + signature} - ${command.description()}');
            }
            Sys.println('');
        }
    }
}