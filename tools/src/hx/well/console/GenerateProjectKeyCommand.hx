package hx.well.console;

import haxe.crypto.Base64;

class GenerateProjectKeyCommand extends AbstractCommand<String> {
    public override function group():String {
        return "generate";
    }

    public function signature():String {
        return "key";
    }

    public function description():String {
        return "Generate a new secure key for the application.";
    }

    public function handle():String {
        var cryptoKey = Base64.encode(System.secureRandomBytes(32));
        Sys.println('APP_KEY=${cryptoKey}');
        return cryptoKey;
    }
}