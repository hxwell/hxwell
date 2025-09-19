package hx.well.console;

import haxe.crypto.Base64;
import haxe.crypto.random.SecureRandom;

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
        var cryptoKey = Base64.encode(SecureRandom.bytes(32));
        Sys.println('APP_KEY=${cryptoKey}');
        return cryptoKey;
    }
}