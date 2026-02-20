package hx.well.cache;
import sys.FileSystem;
import haxe.crypto.Md5;
import sys.io.File;
import hx.well.facades.Config;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import sys.io.FileInput;
import sys.io.FileSeek;
import uuid.Uuid;
import hx.well.thread.MutexPool;

class FileSystemCacheStore implements ICacheStore {
    public static var header = "HXWELL";
    public static var version:Int = 0;
    public var path(get, null):String;

    public function get_path():String {
        return Config.get("http.cache_path");
    }

    private var mutexPool:MutexPool = new MutexPool();

    public function new() {
        #if !cli
        FileSystem.createDirectory(path);
        FileSystem.createDirectory('${path}/temp');
        #end
    }

    public function put<T>(key:String, data:T, seconds:Null<Int>):Void {
        var cacheKey:String = cacheKey(key);
        var expireAt:Float = seconds == null ? -1 : Sys.time() + seconds;

        var serializedData = #if php php.Global.serialize #else haxe.Serializer.run #end(data);

        var bytesBuffer:BytesBuffer = new BytesBuffer();
        bytesBuffer.addString(header);
        bytesBuffer.addByte(version);
        bytesBuffer.addFloat(expireAt);
        bytesBuffer.addInt32(key.length);
        bytesBuffer.addString(key);
        bytesBuffer.addInt32(serializedData.length);
        bytesBuffer.addString(serializedData);
        var temp = '${path}/temp/${Uuid.v5(key)}';
        File.saveBytes(temp, bytesBuffer.getBytes());

        mutexPool.acquire(cacheKey);
        try {
            if(FileSystem.exists('${path}/${cacheKey}'))
                FileSystem.deleteFile('${path}/${cacheKey}');

            FileSystem.rename(temp, '${path}/${cacheKey}');
        } catch (e) {
            // TODO: Log error
        }
        mutexPool.release(cacheKey);
    }

    private function getRaw(key:String):FileSystemCacheEntry {
        var cacheKey:String = cacheKey(key);
        if(!FileSystem.exists('${path}/${cacheKey}'))
            return null;

        var cacheRaw:Bytes = null;
        mutexPool.acquire(cacheKey);
        try {
            cacheRaw = File.getBytes('${path}/${cacheKey}');
        } catch (e) {
            // TODO: Log error
        }
        mutexPool.release(cacheKey);

        if(cacheRaw == null)
            return null;

        var cacheRawInput = new BytesInput(cacheRaw);
        var header = cacheRawInput.readString(header.length);
        var version = cacheRawInput.readByte();
        var expireAt = cacheRawInput.readFloat();
        var keyLength = cacheRawInput.readInt32();
        var key = cacheRawInput.readString(keyLength);
        var serializedDataLength = cacheRawInput.readInt32();
        var serializedData = cacheRawInput.readString(serializedDataLength);

        return {
            data: #if php php.Global.unserialize #else haxe.Unserializer.run #end(serializedData),
            expireAt: expireAt
        };
    }

    public function get<T>(key:String, ?defaultValue:T):T {
        var cacheKey:String = cacheKey(key);
        var cacheData:FileSystemCacheEntry = getRaw(key);

        if(cacheData == null || (cacheData.expireAt != -1 && cacheData.expireAt < Sys.time()))
            return defaultValue;

        return cacheData.data;
    }

    public function has(key:String):Bool {
        var cacheKey:String = cacheKey(key);
        return FileSystem.exists('${path}/${cacheKey}');
    }

    public function forget(key:String):Bool {
        var cacheKey:String = cacheKey(key);

        var success:Bool = true;
        mutexPool.acquire(cacheKey);
        try {
            FileSystem.deleteFile('${path}/${cacheKey}');
        } catch (e) {
            success = false;
        }
        mutexPool.release(cacheKey);

        return success;
    }

    public function cacheKey(key:String):String {
        return Md5.encode(key);
    }

    public function leftTime(key:String):Int {
        var data = getRaw(key);
        if(data == null || data.expireAt < Sys.time())
            return 0;

        return Math.floor(data.expireAt - Sys.time());
    }

    public function touch(key:String, seconds:Null<Int>):Bool {
        var cacheKey:String = cacheKey(key);
        var filePath:String = '${path}/${cacheKey}';

        if(!FileSystem.exists(filePath))
            return false;

        var expireAt:Float = seconds == null ? -1 : Sys.time() + seconds;

        mutexPool.acquire(cacheKey);
        try {
            var file = File.update(filePath, true);
            file.seek(header.length + 1, FileSeek.SeekBegin);
            file.writeFloat(expireAt);
            file.close();
        } catch (e) {
            mutexPool.release(cacheKey);
            return false;
        }
        mutexPool.release(cacheKey);
        return true;
    }

    public function forever<T>(key:String, data:T):Void {
        put(key, data, null);
    }

    public function expireCache():Void {
        var cachePaths = FileSystem.readDirectory(path);
        for(cachePath in cachePaths) {
            var fullCachePath:String = '${path}/${cachePath}';
            var expireAt:Float;
            mutexPool.acquire(cachePath);
            try {
                var file:FileInput = File.read(fullCachePath, true);
                file.seek(header.length + 1, FileSeek.SeekBegin);
                expireAt = file.readFloat();
                file.close();

                if(expireAt != -1 && expireAt < Sys.time()) {
                    FileSystem.deleteFile(fullCachePath);
                }
            } catch(e) {

            }
            mutexPool.release(cachePath);
        }
    }

    public function flush():Void {
        var cachePaths = FileSystem.readDirectory(path);
        for (cachePath in cachePaths) {
            if (cachePath == "temp")
                continue;
            var fullCachePath:String = '${path}/${cachePath}';
            mutexPool.acquire(cachePath);
            try {
                FileSystem.deleteFile(fullCachePath);
            } catch (e) {
                // TODO: Log error
            }
            mutexPool.release(cachePath);
        }
    }

    public function getMany<T>(keys:Array<String>):Map<String, T> {
        var result:Map<String, T> = new Map();
        for (key in keys) {
            var value:T = get(key);
            if (value != null) {
                result.set(key, value);
            }
        }
        return result;
    }

    public function putMany<T>(values:Map<String, T>, seconds:Null<Int>):Void {
        for (key => value in values) {
            put(key, value, seconds);
        }
    }
}

typedef FileSystemCacheEntry = {
    var data:Dynamic;
    var expireAt:Float;
}