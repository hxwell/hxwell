package hx.well;
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
}