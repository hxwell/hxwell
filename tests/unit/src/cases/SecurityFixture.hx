package cases;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import hx.well.HxWell;
import hx.well.facades.Config;
import hx.well.facades.Environment;
import hx.well.http.Request;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseStatic;
import hx.well.internal.SecureToken;
import hx.well.route.Route;
import hx.well.route.RouteElement;
import sys.FileSystem;

class SecurityFixture {
    public var root:String;
    var publicPath:String;
    var cachePath:String;
    var sessionPath:String;
    var appName:String;
    var appKey:String;
    var links:Array<String> = [];

    public function new() {
        // Initialize HxWell before configuring the isolated test environment.
        HxWell.middlewares = [];
        Route.routes = [];
        Route.routeByName = new Map();
        RouteElement.groups = [];
        publicPath = Config.get("http.public_path");
        cachePath = Config.get("http.cache_path");
        sessionPath = Config.get("session.path");
        appName = Environment.get("APP_NAME");
        appKey = Environment.get("APP_KEY");
        Environment.set("APP_NAME", "security_test");
        Environment.set("APP_KEY", Base64.encode(Bytes.ofString("0123456789abcdef0123456789abcdef")));
        root = Sys.getCwd() + "/out/security-" + SecureToken.generate(16);
        for(dir in ["public", "cache/temp", "sessions/temp"])
            FileSystem.createDirectory(root + "/" + dir);
        Config.set("http.public_path", root + "/public");
        Config.set("http.cache_path", root + "/cache");
        Config.set("session.path", root + "/sessions");
        ResponseStatic.reset();
    }

    public function symlink(target:String, path:String):Void {
        if(Sys.command("ln", ["-s", target, path]) != 0)
            throw new haxe.Exception("Could not create symlink fixture");
        links.push(path);
    }

    public static function request(path:String = "/", method:String = "GET"):Request {
        var request = new Request();
        request.method = method;
        request.path = path;
        request.host = "localhost";
        return request;
    }

    public function close():Void {
        RequestStatic.reset();
        ResponseStatic.clear();
        // Remove links first; never follow a fixture link while deleting its tree.
        for(link in links)
            FileSystem.deleteFile(link);
        removeTree(root);
        Config.set("http.public_path", publicPath);
        Config.set("http.cache_path", cachePath);
        Config.set("session.path", sessionPath);
        Environment.set("APP_NAME", appName);
        Environment.set("APP_KEY", appKey);
    }

    static function removeTree(path:String):Void {
        if(FileSystem.isDirectory(path)) {
            for(name in FileSystem.readDirectory(path))
                removeTree(path + "/" + name);
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }
}
