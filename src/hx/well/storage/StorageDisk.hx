package hx.well.storage;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Path;
import hx.well.http.InputResponse;
import hx.well.internal.SecureToken;

/** Laravel-style filesystem operations, independent of the HTTP driver. */
class StorageDisk {
    var adapter:IStorageAdapter;
    var prefix:String;
    var baseUrl:String;
    var throwsErrors:Bool;
    var readOnly:Bool;
    var defaultVisibility:Null<String>;
    var temporaryUrlBuilder:(String, Date, Map<String, String>)->String;

    public function new(adapter:IStorageAdapter, ?config:StorageDiskConfig) {
        this.adapter = adapter;
        prefix = config == null || config.prefix == null ? "" : StoragePath.normalize(config.prefix);
        baseUrl = config == null ? null : config.url;
        throwsErrors = config != null && config.throw_errors == true;
        readOnly = config != null && config.read_only == true;
        defaultVisibility = config == null || config.visibility == null ? null : StoragePath.visibility(config.visibility);
    }

    function scoped(path:String, file:Bool = false):String {
        var normalized = file ? StoragePath.file(path) : StoragePath.normalize(path);
        return prefix == "" ? normalized : (normalized == "" ? prefix : prefix + "/" + normalized);
    }

    function unscoped(paths:Array<String>):Array<String> {
        if (prefix == "") return paths;
        var start = prefix + "/";
        return [for (path in paths) {
            if (!StringTools.startsWith(path, start)) throw new InvalidStoragePath(path);
            path.substr(start.length);
        }];
    }

    function writable(path:String):Void {
        if (readOnly) throw new StorageException("write to read-only disk", path);
    }

    function failed(operation:String, path:String, error:Dynamic):Void {
        if (Std.isOfType(error, InvalidStoragePath)) throw error;
        if (throwsErrors) {
            if (Std.isOfType(error, StorageException)) throw error;
            var previous:haxe.Exception = Std.isOfType(error, haxe.Exception) ? cast error : new haxe.Exception(Std.string(error));
            throw new StorageException(operation, path, previous);
        }
    }

    public function exists(path:String):Bool {
        var normalized = scoped(path);
        return adapter.fileExists(normalized) || adapter.directoryExists(normalized);
    }

    public function missing(path:String):Bool { return !exists(path); }
    public function fileExists(path:String):Bool { return adapter.fileExists(scoped(path)); }
    public function fileMissing(path:String):Bool { return !fileExists(path); }
    public function directoryExists(path:String):Bool { return adapter.directoryExists(scoped(path)); }
    public function directoryMissing(path:String):Bool { return !directoryExists(path); }

    public function getBytes(path:String):Null<Bytes> {
        var input = readStream(path);
        if (input == null) return null;
        try {
            var bytes = input.readAll();
            input.close();
            return bytes;
        } catch (e:Dynamic) {
            try input.close() catch (_:Dynamic) {}
            failed("read file", path, e);
            return null;
        }
    }

    public function get(path:String):Null<String> {
        var bytes = getBytes(path);
        return bytes == null ? null : bytes.toString();
    }

    public function json(path:String):Dynamic {
        var contents = get(path);
        if (contents == null) return null;
        try return haxe.Json.parse(contents) catch (_:Dynamic) return null;
    }

    /** The caller owns this stream and must close it. */
    public function readStream(path:String):Null<Input> {
        var normalized = scoped(path, true);
        try return adapter.readStream(normalized) catch (e:Dynamic) {
            failed("read stream", path, e);
            return null;
        }
    }

    public function put(path:String, contents:StorageContents, ?options:StorageOptions):Bool {
        var value:Dynamic = contents;
        if (value == null) throw new haxe.Exception("Storage contents must be a String, Bytes or Input.");
        if (Std.isOfType(value, Input)) return writeStream(path, cast value, options);
        var bytes:Bytes;
        if (Std.isOfType(value, String)) bytes = Bytes.ofString(cast value);
        else if (Std.isOfType(value, Bytes)) bytes = cast value;
        else throw new haxe.Exception("Storage contents must be a String, Bytes or Input.");
        var input = new BytesInput(bytes);
        try {
            var result = writeStream(path, input, options);
            input.close();
            return result;
        } catch (e:Dynamic) {
            input.close();
            throw e;
        }
    }

    /** Does not close the supplied input. */
    public function writeStream(path:String, input:Input, ?options:StorageOptions):Bool {
        var normalized = scoped(path, true);
        if (input == null) throw new haxe.Exception("Storage input must not be null.");
        var value:Dynamic = options;
        var visibility:String = value == null ? defaultVisibility
            : (Std.isOfType(value, String) ? cast value : value.visibility);
        if (visibility != null) StoragePath.visibility(visibility);
        try {
            writable(path);
            adapter.writeStream(normalized, input, visibility);
            return true;
        } catch (e:Dynamic) {
            failed("write stream", path, e);
            return false;
        }
    }

    /** Stream an application-owned local file into this disk. */
    public function putFileAs(directory:String, source:String, name:String, ?options:StorageOptions):Null<String> {
        var destination = StoragePath.file(StoragePath.normalize(directory) + "/" + StoragePath.file(name));
        var input:Input = null;
        try {
            writable(destination);
            input = sys.io.File.read(source, true);
            var success = writeStream(destination, input, options);
            input.close();
            return success ? destination : null;
        } catch (e:Dynamic) {
            if (input != null) try input.close() catch (_:Dynamic) {}
            failed("store local file", destination, e);
            return null;
        }
    }

    public function putFile(directory:String, source:String, ?options:StorageOptions):Null<String> {
        var extension = Path.extension(source);
        return putFileAs(directory, source, SecureToken.generate(40) + (extension == "" ? "" : "." + extension), options);
    }

    public function append(path:String, data:String, ?separator:String):Bool {
        return updateText(path, data, separator, false);
    }

    public function prepend(path:String, data:String, ?separator:String):Bool {
        return updateText(path, data, separator, true);
    }

    function updateText(path:String, data:String, separator:String, prepend:Bool):Bool {
        scoped(path, true);
        if (separator == null) separator = Sys.systemName() == "Windows" ? "\r\n" : "\n";
        return StorageLock.run(this.path(path), () -> {
            try {
                writable(path);
                if (!fileExists(path)) return put(path, data);
                var previous = get(path);
                if (previous == null) return false;
                return put(path, prepend ? data + separator + previous : previous + separator + data);
            } catch (e:Dynamic) {
                failed(prepend ? "prepend" : "append", path, e);
                return false;
            }
        });
    }

    public function delete(paths:haxe.extern.EitherType<String, Array<String>>):Bool {
        var value:Dynamic = paths;
        var list:Array<String> = Std.isOfType(value, String) ? [cast value] : cast value;
        if (list == null) throw new InvalidStoragePath(null);
        var normalized = [for (path in list) scoped(path, true)];
        var success = true;
        for (i in 0...list.length) try {
            writable(list[i]);
            adapter.delete(normalized[i]);
        } catch (e:Dynamic) {
            failed("delete file", list[i], e);
            success = false;
        }
        return success;
    }

    public function copy(from:String, to:String):Bool {
        var source = scoped(from, true);
        var destination = scoped(to, true);
        try {
            writable(to);
            adapter.copy(source, destination);
            return true;
        } catch (e:Dynamic) {
            failed("copy file", from, e);
            return false;
        }
    }

    public function move(from:String, to:String):Bool {
        var source = scoped(from, true);
        var destination = scoped(to, true);
        try {
            writable(to);
            adapter.move(source, destination);
            return true;
        } catch (e:Dynamic) {
            failed("move file", from, e);
            return false;
        }
    }

    public function size(path:String):Int { return adapter.size(scoped(path, true)); }
    public function lastModified(path:String):Float { return adapter.lastModified(scoped(path, true)); }
    public function getVisibility(path:String):String { return adapter.getVisibility(scoped(path)); }

    public function mimeType(path:String):Null<String> {
        var normalized = scoped(path, true);
        try return adapter.mimeType(normalized) catch (e:Dynamic) {
            failed("get MIME type", path, e);
            return null;
        }
    }

    public function setVisibility(path:String, visibility:String):Bool {
        var normalized = scoped(path);
        StoragePath.visibility(visibility);
        try {
            writable(path);
            adapter.setVisibility(normalized, visibility);
            return true;
        } catch (e:Dynamic) {
            failed("set visibility", path, e);
            return false;
        }
    }

    public function checksum(path:String, algorithm:String = "md5"):Null<String> {
        if (algorithm != "md5" && algorithm != "sha256") throw new haxe.Exception("Supported storage checksums: md5, sha256.");
        var bytes = getBytes(path);
        if (bytes == null) return null;
        return algorithm == "md5" ? haxe.crypto.Md5.make(bytes).toHex() : haxe.crypto.Sha256.make(bytes).toHex();
    }

    public function files(directory:String = "", recursive:Bool = false):Array<String> {
        return unscoped(adapter.files(scoped(directory), recursive));
    }

    public function allFiles(directory:String = ""):Array<String> { return files(directory, true); }

    public function directories(directory:String = "", recursive:Bool = false):Array<String> {
        return unscoped(adapter.directories(scoped(directory), recursive));
    }

    public function allDirectories(directory:String = ""):Array<String> { return directories(directory, true); }

    public function makeDirectory(path:String):Bool {
        var normalized = scoped(path);
        try {
            writable(path);
            adapter.makeDirectory(normalized);
            return true;
        } catch (e:Dynamic) {
            failed("create directory", path, e);
            return false;
        }
    }

    public function deleteDirectory(directory:String):Bool {
        var normalized = scoped(directory);
        try {
            writable(directory);
            adapter.deleteDirectory(normalized);
            return true;
        } catch (e:Dynamic) {
            failed("delete directory", directory, e);
            return false;
        }
    }

    public function path(path:String):String { return adapter.path(scoped(path)); }

    /** Unlike Laravel's local URL concatenation, encode each path component. */
    public function url(path:String):String {
        var normalized = scoped(path);
        if (baseUrl == null) throw new haxe.Exception("This disk has no public URL configured.");
        var base = baseUrl;
        while (StringTools.endsWith(base, "/")) base = base.substr(0, base.length - 1);
        return base + "/" + [for (part in normalized.split("/")) StringTools.urlEncode(part)].join("/");
    }

    public function providesTemporaryUrls():Bool { return temporaryUrlBuilder != null; }

    public function buildTemporaryUrlsUsing(callback:(String, Date, Map<String, String>)->String):Void {
        temporaryUrlBuilder = callback;
    }

    public function temporaryUrl(path:String, expiration:Date, ?options:Map<String, String>):String {
        var normalized = StoragePath.file(path);
        if (temporaryUrlBuilder == null) throw new haxe.Exception("No temporary URL builder is configured for this disk.");
        if (expiration == null) throw new haxe.Exception("An expiration date is required.");
        return temporaryUrlBuilder(normalized, expiration, options == null ? new Map() : options);
    }

    public function response(path:String, ?name:String, ?headers:Map<String, String>, disposition:String = "inline"):InputResponse {
        var normalized = StoragePath.file(path);
        if (disposition != "inline" && disposition != "attachment") throw new haxe.Exception("Invalid content disposition.");
        var filename = name == null ? Path.withoutDirectory(normalized) : name;
        if (filename == "" || ~/[\x00-\x1f\x7f\/\\]/.match(filename)) throw new haxe.Exception("Invalid download filename.");
        var fallback = new StringBuf();
        for (i in 0...filename.length) {
            var char = filename.charCodeAt(i);
            fallback.add(char < 32 || char > 126 || char == 34 || char == 92 || char == 37 ? "_" : filename.charAt(i));
        }
        var downloadName = '${disposition}; filename="${fallback.toString()}"; filename*=UTF-8\'\'${StringTools.urlEncode(filename)}';
        var type = mimeType(normalized) ?? "application/octet-stream";
        var input = readStream(normalized);
        if (input == null) throw new StorageException("download file", path);
        try {
            // Local writes rename a new inode into place. Derive length from
            // the opened descriptor so a replacement cannot change framing.
            var result:InputResponse = Std.isOfType(input, sys.io.FileInput)
                ? new hx.well.http.FileInputResponse(cast input)
                : new InputResponse(input, haxe.Int64.ofInt(size(normalized)));
            if (haxe.Int64.compare(result.contentLength, haxe.Int64.ofInt(0)) < 0)
                throw new StorageException("read file size outside the target Int range", path);
            var length = haxe.Int64.toStr(result.contentLength);
            var present:Map<String, Bool> = [];
            if (headers != null) for (key => value in headers) {
                result.header(key, value);
                var lower = hx.well.http.HttpSyntax.lowerAscii(key);
                if (lower == "content-length" && value != length)
                    throw new haxe.Exception("Download Content-Length must match the stored file size.");
                present.set(lower, true);
            }
            if (!present.exists("content-type")) result.header("Content-Type", type);
            if (!present.exists("content-disposition")) result.header("Content-Disposition", downloadName);
            if (!present.exists("x-content-type-options")) result.header("X-Content-Type-Options", "nosniff");
            return result;
        } catch (e:Dynamic) {
            input.close();
            throw e;
        }
    }

    public function download(path:String, ?name:String, ?headers:Map<String, String>):InputResponse {
        return response(path, name, headers, "attachment");
    }

    public function assertExists(paths:haxe.extern.EitherType<String, Array<String>>, ?contents:String):StorageDisk {
        var value:Dynamic = paths;
        var list:Array<String> = Std.isOfType(value, String) ? [cast value] : cast value;
        for (path in list) if (!exists(path) || (contents != null && get(path) != contents))
            throw new haxe.Exception('Storage assertion failed: expected "${path}" to exist with the requested contents.');
        return this;
    }

    public function assertMissing(paths:haxe.extern.EitherType<String, Array<String>>):StorageDisk {
        var value:Dynamic = paths;
        var list:Array<String> = Std.isOfType(value, String) ? [cast value] : cast value;
        for (path in list) if (exists(path)) throw new haxe.Exception('Storage assertion failed: "${path}" exists.');
        return this;
    }

    public function assertCount(path:String, count:Int, recursive:Bool = false):StorageDisk {
        if (files(path, recursive).length != count) throw new haxe.Exception('Storage assertion failed: expected ${count} files in "${path}".');
        return this;
    }

    public function assertDirectoryEmpty(path:String):StorageDisk {
        if (!directoryExists(path) || allFiles(path).length != 0 || allDirectories(path).length != 0)
            throw new haxe.Exception('Storage assertion failed: directory "${path}" is not empty.');
        return this;
    }
}
