package hx.well.facades;

import hx.well.config.FilesystemsConfig;
import hx.well.storage.IStorageAdapter;
import hx.well.storage.LocalStorageAdapter;
import hx.well.storage.StorageContents;
import hx.well.storage.StorageDisk;
import hx.well.storage.StorageDiskConfig;
import hx.well.storage.StorageOptions;
import hx.well.storage.StoragePath;
import hx.well.internal.SecureToken;

/** Named disks are shared; configure/register them during application boot. */
class Storage {
    static var disks:Map<String, StorageDisk> = [];
    static var creators:Map<String, StorageDiskConfig->IStorageAdapter> = [];
    #if target.threaded
    static var mutex = new sys.thread.Mutex();
    #end

    static function synchronized<T>(callback:Void->T):T {
        #if target.threaded
        mutex.acquire();
        try {
            var value = callback();
            mutex.release();
            return value;
        } catch (e:Dynamic) {
            mutex.release();
            throw e;
        }
        #else
        return callback();
        #end
    }

    static function configuration():FilesystemsConfig {
        // The built-in config keeps existing apps source-compatible; normal
        // HxWell startup initializes it along with the application's configs.
        return synchronized(() -> {
            if (Config.get("filesystems") == null) Config.set("filesystems", new FilesystemsConfig());
            return Config.get("filesystems");
        });
    }

    public static function getDefaultDriver():String { return configuration().default_disk; }

    public static function disk(?name:String):StorageDisk {
        if (name == null) name = getDefaultDriver();
        var cached = synchronized(() -> disks.get(name));
        if (cached != null) return cached;
        var configs = configuration().disks;
        if (!configs.exists(name)) throw new haxe.Exception('Storage disk "${name}" is not configured.');
        // Build outside the registry lock: a custom factory may resolve another
        // disk. A concurrent first lookup publishes only one shared instance.
        var created = build(configs.get(name));
        return synchronized(() -> {
            var winner = disks.get(name);
            if (winner != null) return winner;
            disks.set(name, created);
            return created;
        });
    }

    public static function drive(?name:String):StorageDisk { return disk(name); }

    public static function build(config:StorageDiskConfig):StorageDisk {
        return buildResolved(config, []);
    }

    static function buildResolved(config:StorageDiskConfig, chain:Array<String>):StorageDisk {
        if (config == null || config.driver == null) throw new haxe.Exception("A storage driver is required.");
        if (config.driver == "scoped") {
            if (config.disk == null || config.prefix == null || StoragePath.normalize(config.prefix) == "")
                throw new haxe.Exception("A scoped disk requires a disk name and nonempty prefix.");
            if (chain.indexOf(config.disk) >= 0) throw new haxe.Exception("Circular scoped storage configuration.");
            var parent = configuration().disks.get(config.disk);
            if (parent == null) throw new haxe.Exception('Storage disk "${config.disk}" is not configured.');
            var merged:StorageDiskConfig = cast Reflect.copy(parent);
            merged.prefix = parent.prefix == null ? StoragePath.normalize(config.prefix)
                : StoragePath.normalize(parent.prefix) + "/" + StoragePath.normalize(config.prefix);
            if (config.visibility != null) merged.visibility = config.visibility;
            if (config.throw_errors != null) merged.throw_errors = config.throw_errors;
            merged.read_only = parent.read_only == true || config.read_only == true;
            return buildResolved(merged, chain.concat([config.disk]));
        }
        var factory = synchronized(() -> creators.get(config.driver));
        var adapter:IStorageAdapter = factory != null ? factory(config) : switch (config.driver) {
            case "local": new LocalStorageAdapter(config);
            default: throw new haxe.Exception('Storage driver "${config.driver}" is not registered. Use Storage.extend().');
        };
        if (adapter == null) throw new haxe.Exception("The storage factory returned no adapter.");
        return new StorageDisk(adapter, config);
    }

    public static function extend(driver:String, creator:StorageDiskConfig->IStorageAdapter):Void {
        if (driver == null || driver == "" || driver == "scoped" || creator == null)
            throw new haxe.Exception("A custom storage driver requires a name and factory.");
        synchronized(() -> { creators.set(driver, creator); return true; });
    }

    public static function set(name:String, instance:StorageDisk):Void {
        if (name == null || instance == null) throw new haxe.Exception("A disk name and instance are required.");
        synchronized(() -> { disks.set(name, instance); return true; });
    }

    public static function forgetDisk(name:String):Void {
        synchronized(() -> { disks.remove(name); return true; });
    }

    public static function purge(?name:String):Void { forgetDisk(name == null ? getDefaultDriver() : name); }

    /** Replace a named disk with a unique local test disk. The caller owns the
        returned directory's lifecycle; no configured/live disk is ever erased. */
    public static function fake(?name:String, ?temporaryDirectory:String):StorageDisk {
        if (name == null) name = getDefaultDriver();
        if (temporaryDirectory == null) {
            temporaryDirectory = Sys.getEnv("TMPDIR");
            if (temporaryDirectory == null) temporaryDirectory = Sys.getEnv("TEMP");
            if (temporaryDirectory == null) temporaryDirectory = Sys.systemName() == "Windows" ? "." : "/tmp";
        }
        var root = haxe.io.Path.join([temporaryDirectory, "hxwell-storage-" + SecureToken.generate(32)]);
        var instance = build({driver: "local", root: root, throw_errors: true});
        instance.makeDirectory("");
        set(name, instance);
        return instance;
    }

    public static function exists(path:String):Bool { return disk().exists(path); }
    public static function missing(path:String):Bool { return disk().missing(path); }
    public static function fileExists(path:String):Bool { return disk().fileExists(path); }
    public static function fileMissing(path:String):Bool { return disk().fileMissing(path); }
    public static function directoryExists(path:String):Bool { return disk().directoryExists(path); }
    public static function directoryMissing(path:String):Bool { return disk().directoryMissing(path); }
    public static function get(path:String):Null<String> { return disk().get(path); }
    public static function getBytes(path:String):Null<haxe.io.Bytes> { return disk().getBytes(path); }
    public static function json(path:String):Dynamic { return disk().json(path); }
    public static function readStream(path:String):Null<haxe.io.Input> { return disk().readStream(path); }
    public static function put(path:String, contents:StorageContents, ?options:StorageOptions):Bool { return disk().put(path, contents, options); }
    public static function writeStream(path:String, input:haxe.io.Input, ?options:StorageOptions):Bool { return disk().writeStream(path, input, options); }
    public static function putFile(directory:String, source:String, ?options:StorageOptions):Null<String> { return disk().putFile(directory, source, options); }
    public static function putFileAs(directory:String, source:String, name:String, ?options:StorageOptions):Null<String> { return disk().putFileAs(directory, source, name, options); }
    public static function append(path:String, data:String, ?separator:String):Bool { return disk().append(path, data, separator); }
    public static function prepend(path:String, data:String, ?separator:String):Bool { return disk().prepend(path, data, separator); }
    public static function delete(paths:haxe.extern.EitherType<String, Array<String>>):Bool { return disk().delete(paths); }
    public static function copy(from:String, to:String):Bool { return disk().copy(from, to); }
    public static function move(from:String, to:String):Bool { return disk().move(from, to); }
    public static function size(path:String):Int { return disk().size(path); }
    public static function lastModified(path:String):Float { return disk().lastModified(path); }
    public static function mimeType(path:String):Null<String> { return disk().mimeType(path); }
    public static function getVisibility(path:String):String { return disk().getVisibility(path); }
    public static function setVisibility(path:String, visibility:String):Bool { return disk().setVisibility(path, visibility); }
    public static function checksum(path:String, algorithm:String = "md5"):Null<String> { return disk().checksum(path, algorithm); }
    public static function files(directory:String = "", recursive:Bool = false):Array<String> { return disk().files(directory, recursive); }
    public static function allFiles(directory:String = ""):Array<String> { return disk().allFiles(directory); }
    public static function directories(directory:String = "", recursive:Bool = false):Array<String> { return disk().directories(directory, recursive); }
    public static function allDirectories(directory:String = ""):Array<String> { return disk().allDirectories(directory); }
    public static function makeDirectory(path:String):Bool { return disk().makeDirectory(path); }
    public static function deleteDirectory(path:String):Bool { return disk().deleteDirectory(path); }
    public static function path(path:String):String { return disk().path(path); }
    public static function url(path:String):String { return disk().url(path); }
    public static function providesTemporaryUrls():Bool { return disk().providesTemporaryUrls(); }
    public static function buildTemporaryUrlsUsing(callback:(String, Date, Map<String, String>)->String):Void { disk().buildTemporaryUrlsUsing(callback); }
    public static function temporaryUrl(path:String, expiration:Date, ?options:Map<String, String>):String { return disk().temporaryUrl(path, expiration, options); }
    public static function response(path:String, ?name:String, ?headers:Map<String, String>, disposition:String = "inline"):hx.well.http.InputResponse { return disk().response(path, name, headers, disposition); }
    public static function download(path:String, ?name:String, ?headers:Map<String, String>):hx.well.http.InputResponse { return disk().download(path, name, headers); }
    public static function assertExists(paths:haxe.extern.EitherType<String, Array<String>>, ?contents:String):StorageDisk { return disk().assertExists(paths, contents); }
    public static function assertMissing(paths:haxe.extern.EitherType<String, Array<String>>):StorageDisk { return disk().assertMissing(paths); }
    public static function assertCount(path:String, count:Int, recursive:Bool = false):StorageDisk { return disk().assertCount(path, count, recursive); }
    public static function assertDirectoryEmpty(path:String):StorageDisk { return disk().assertDirectoryEmpty(path); }
}
