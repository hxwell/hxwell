package hx.well.tools;
class CommandLineTools {
    public static function parseCommandLine(input:String):Array<String> {
        var args:Array<String> = [];
        var current = new StringBuf();
        var inQuotes = false;
        var escaped = false;

        for (i in 0...input.length) {
            var char = input.charAt(i);

            if (escaped) {
                // Insert the character after the escape character as is
                current.add(char);
                escaped = false;
                continue;
            }

            switch (char) {
                case "\\":
                    escaped = true;

                case "\"":
                    inQuotes = !inQuotes;

                case " ":
                    if (inQuotes) {
                        current.add(char);
                    } else if (current.length > 0) {
                        args.push(current.toString());
                        current = new StringBuf();
                    }

                default:
                    current.add(char);
            }
        }

        // Add last argument
        if (current.length > 0) {
            args.push(current.toString());
        }

        return args;
    }
}
