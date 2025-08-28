package hx.well.cache;
import haxe.crypto.Md5;
import hx.well.facades.Config;
import sys.FileSystem;
import sys.io.File;
class FileSystemSessionCacheStore extends FileSystemCacheStore {
    public override function get_path():String {
        return Config.get("session.path");
    }
}