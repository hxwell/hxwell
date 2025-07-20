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

#if (target.threaded)
import sys.thread.Mutex;
#else
import hx.well.thread.FakeMutex as Mutex;
#end

class FileSystemCacheStore implements ICacheStore {
    public static var header = "HXWELL";
    public static var version:Int = 0;
    public var path(get, null):String;

    public function get_path():String {
        return Config.get("cache.path", "cache");
    }

    private var mutex:Mutex = new Mutex();

    public function new() {
        #if !cli
        FileSystem.createDirectory(path);
        FileSystem.createDirectory('${path}/temp');
        #end
    }

    public function put<T>(key:String, data:T, seconds:Null<Int>):Void {
        var cacheKey:String = cacheKey(key);
        var expireAt:Float = seconds == null ? -1 : Sys.time() + seconds;

        mutex.acquire();
        try {
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
            FileSystem.rename(temp, '${path}/${cacheKey}');
        } catch (e) {

        }
        mutex.release();
    }

    private function getRaw(key:String):FileSystemCacheEntry {
        var cacheKey:String = cacheKey(key);
        if(!FileSystem.exists('${path}/${cacheKey}'))
            return null;

        var cacheRaw:Bytes = null;
        mutex.acquire();
        try {
            cacheRaw = File.getBytes('${path}/${cacheKey}');
        } catch (e) {

        }
        mutex.release();

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

    public function forget<T>(key:String):Bool {
        var cacheKey:String = cacheKey(key);

        var success:Bool = true;
        mutex.acquire();
        try {
            FileSystem.deleteFile('${path}/${cacheKey}');
        } catch(e) {
            success = false;
        }
        mutex.release();

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

    public function forever<T>(key:String, data:T):Void {
        put(key, data, null);
    }

    public function expireCache():Void {
        var cachePaths = FileSystem.readDirectory(path);
        for(cachePath in cachePaths) {
            var fullCachePath:String = '${path}/${cachePath}';
            var expireAt:Float;
            try {
                mutex.acquire();
                try {
                    var file:FileInput = File.read(fullCachePath, true);
                    file.seek(header.length + 1, FileSeek.SeekBegin);
                    expireAt = file.readFloat();
                    file.close();
                } catch(e) {
                    mutex.release();
                    throw e;
                }
                mutex.release();

                if(expireAt != -1 && expireAt < Sys.time()) {
                    FileSystem.deleteFile(fullCachePath);
                }
            } catch(e) {

            }
        }
    }
}

typedef FileSystemCacheEntry = {
    var data:Dynamic;
    var expireAt:Float;
}