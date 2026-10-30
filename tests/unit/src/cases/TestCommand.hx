package cases;

import utest.Assert;

class TestCommand extends utest.Test {
    function testArgumentsRemainReadableAfterParsingAndReset() {
        var command = new ParsedCommand();
        var input = ["alice", "\"hello world\"", "--flag", "--limit=3"];
        command.args = input;
        Assert.same(input, command.args);
        Assert.equals("alice|hello world|3|true", command.handle());
        command.args = ["bob"];
        Assert.same(["bob"], command.args);
        Assert.equals("bob|none|none|false", command.handle());
    }
}

private class ParsedCommand extends hx.well.console.AbstractCommand<String> {
    public function new() { super(); }
    public function signature():String { return "probe {name} {extra?}"; }
    public function description():String { return "Argument parser regression"; }
    public function handle():String {
        return argument("name") + "|" + argument("extra", "none") + "|" + getOption("limit", "none") + "|" + hasOption("flag");
    }
}
