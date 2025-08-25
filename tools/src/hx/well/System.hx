package hx.well;
import haxe.io.Bytes;
import haxe.io.Bytes.Bytes.alloc;
class System {
    public static function openURL(url:String) {
        switch (Sys.systemName()) {
            case "Windows":
                Sys.command("start", ["", url]);
            case "Mac":
                Sys.command("/usr/bin/open", [url]);
            case "Linux":
                Sys.command("/usr/bin/xdg-open", [url]);
            default:
                trace("Unsupported system for opening URL: " + Sys.systemName());
        }
    }

    public static function secureRandomBytes(length:Int):Bytes {
        var out = Bytes.alloc(length);
         switch (Sys.systemName()) {
            case "Windows":
                var cmd = '[byte[]]$$b = New-Object byte[] ' + length + '; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($$b); ($$b | ForEach-Object { $$_.ToString(\'X2\') }) -join \'\'';
                var p = new sys.io.Process("powershell", ["-NoProfile", "-Command", cmd]);
                var hexValues = p.stdout.read(length * 2).toString();
                // Validate the hex string and length with regex
                var hexValidateRegex = new EReg('^[0-9A-Fa-f]{${length * 2}}$', "");
                if (!hexValidateRegex.match(hexValues))
                    throw "Failed to generate secure random bytes.";

                out = Bytes.ofHex(hexValues);
            case "Linux" | "Mac":
                var input = sys.io.File.read("/dev/urandom");
                input.readBytes(out, 0, length);
                input.close();
            default:
                trace("Unsupported system for secure random string: " + Sys.systemName());
        }
        return out;
    }
}