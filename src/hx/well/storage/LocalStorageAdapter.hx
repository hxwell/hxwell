package hx.well.storage;

import haxe.io.Input;
import haxe.io.Path;
import hx.well.internal.SecureToken;
import sys.FileSystem;
import sys.io.File;

/** Local disk. Symlinks below the configured root (including dangling links)
    are rejected. The root and its parents must be controlled by the application. */
class LocalStorageAdapter implements IStorageAdapter {
    public var root(default, null):String;
    var defaultVisibility:String;
    var directoryVisibility:String;

    public function new(config:StorageDiskConfig) {
        if (config.root == null || config.root == "" || config.root.indexOf("\x00") >= 0)
            throw new haxe.Exception("A local storage disk requires a nonempty root.");
        defaultVisibility = StoragePath.visibility(config.visibility == null ? "private" : config.visibility);
        directoryVisibility = StoragePath.visibility(config.directory_visibility == null ? "private" : config.directory_visibility);
        var absolute = Path.normalize(FileSystem.absolutePath(config.root));
        var ancestor = absolute;
        var suffix:Array<String> = [];
        while (!FileSystem.exists(ancestor)) {
            var parent = Path.directory(ancestor);
            if (parent == ancestor || parent == "") throw new InvalidStoragePath(config.root);
            if (FileSystem.exists(parent) && FileSystem.readDirectory(parent).indexOf(Path.withoutDirectory(ancestor)) >= 0)
                throw new InvalidStoragePath(config.root);
            suffix.unshift(Path.withoutDirectory(ancestor));
            ancestor = parent;
        }
        var canonical = FileSystem.fullPath(ancestor);
        if (canonical == null || !FileSystem.isDirectory(ancestor)) throw new InvalidStoragePath(config.root);
        root = Path.normalize(Path.join([canonical].concat(suffix)));
    }

    /** Check every existing component, not only the final file. This also covers
        writes into nonexistent descendants and links that point back into root. */
    function checked(absolute:String):String {
        var parent = Path.directory(absolute);
        if (FileSystem.exists(absolute)) {
            var canonical = FileSystem.fullPath(absolute);
            if (canonical == null || Path.normalize(canonical) != absolute)
                throw new InvalidStoragePath(absolute);
            var kind = FileSystem.stat(absolute).mode & 61440;
            if (kind != 0 && kind != 32768 && kind != 16384)
                throw new InvalidStoragePath(absolute);
        } else if (parent != absolute && FileSystem.exists(parent)
            && FileSystem.readDirectory(parent).indexOf(Path.withoutDirectory(absolute)) >= 0) {
            // A concurrent writer may have created this directory after the
            // first exists() check. Validate it normally before classifying
            // the still-unresolvable entry as a dangling link.
            if (FileSystem.exists(absolute)) return checked(absolute);
            throw new InvalidStoragePath(absolute);
        }
        return absolute;
    }

    public function path(path:String):String {
        checked(root);
        // A removed root may have a substituted parent; validate the first
        // existing ancestor as well before creating anything under it.
        var ancestor = root;
        while (!FileSystem.exists(ancestor)) {
            checked(ancestor);
            var parent = Path.directory(ancestor);
            if (parent == ancestor || parent == "") throw new InvalidStoragePath(path);
            ancestor = parent;
        }
        checked(ancestor);
        var current = root;
        var normalized = StoragePath.normalize(path);
        if (normalized != "") for (part in normalized.split("/")) {
            current = Path.join([current, part]);
            checked(current);
        }
        return current;
    }

    function requireFile(path:String):String {
        var absolute = this.path(StoragePath.file(path));
        if (!FileSystem.exists(absolute) || FileSystem.isDirectory(absolute))
            throw new StorageException("read file", path);
        return absolute;
    }

    function createParents(absolute:String):Void {
        if (FileSystem.exists(absolute)) {
            checked(absolute);
            if (!FileSystem.isDirectory(absolute)) throw new StorageException("create directory", absolute);
            return;
        }
        checked(absolute);
        var parent = Path.directory(absolute);
        createParents(parent);
        try FileSystem.createDirectory(absolute) catch (error:Dynamic) {
            // On JVM, mkdirs() can return false if another writer created the
            // same directory between its existence check and the system call.
            if (!FileSystem.exists(absolute) || !FileSystem.isDirectory(absolute)) throw error;
        }
        checked(absolute);
        LocalPermissions.set(absolute, directoryVisibility, true);
    }

    public function fileExists(path:String):Bool {
        var absolute = this.path(path);
        return FileSystem.exists(absolute) && !FileSystem.isDirectory(absolute);
    }

    public function directoryExists(path:String):Bool {
        var absolute = this.path(path);
        return FileSystem.exists(absolute) && FileSystem.isDirectory(absolute);
    }

    public function readStream(path:String):Input {
        return File.read(requireFile(path), true);
    }

    public function writeStream(path:String, input:Input, ?visibility:String):Void {
        var absolute = this.path(StoragePath.file(path));
        var parent = Path.directory(absolute);
        createParents(parent);
        if (FileSystem.exists(absolute) && FileSystem.isDirectory(absolute))
            throw new StorageException("write file", path);
        var mode = visibility != null ? StoragePath.visibility(visibility)
            : (FileSystem.exists(absolute) ? getVisibility(path) : defaultVisibility);
        var temporary = parent + "/.hxwell-" + SecureToken.generate(32) + ".tmp";
        var output:sys.io.FileOutput = null;
        try {
            output = File.write(temporary, true);
            LocalPermissions.set(temporary, "private", false);
            output.writeInput(input);
            output.flush();
            output.close();
            output = null;
            LocalPermissions.set(temporary, mode, false);
            this.path(path);
            FileSystem.rename(temporary, absolute);
        } catch (e:Dynamic) {
            if (output != null) try output.close() catch (_:Dynamic) {}
            if (FileSystem.exists(temporary)) FileSystem.deleteFile(temporary);
            throw e;
        }
    }

    public function delete(path:String):Void {
        var absolute = this.path(StoragePath.file(path));
        if (!FileSystem.exists(absolute)) return;
        if (FileSystem.isDirectory(absolute)) throw new StorageException("delete file", path);
        FileSystem.deleteFile(absolute);
    }

    public function copy(from:String, to:String):Void {
        requireFile(from);
        this.path(StoragePath.file(to));
        if (from == to) return;
        var input = readStream(from);
        try writeStream(to, input, getVisibility(from)) catch (e:Dynamic) {
            input.close();
            throw e;
        }
        input.close();
    }

    public function move(from:String, to:String):Void {
        var source = requireFile(from);
        var destination = this.path(StoragePath.file(to));
        if (source == destination) return;
        createParents(Path.directory(destination));
        if (FileSystem.exists(destination) && FileSystem.isDirectory(destination))
            throw new StorageException("move file", to);
        FileSystem.rename(source, destination);
    }

    public function size(path:String):Int {
        var size = FileSystem.stat(requireFile(path)).size;
        if (size < 0) throw new StorageException("read file size outside the target Int range", path);
        return size;
    }

    /** Unix timestamp, in seconds (not Haxe Date milliseconds). */
    public function lastModified(path:String):Float {
        return Math.floor(FileSystem.stat(requireFile(path)).mtime.getTime() / 1000);
    }

    /** Portable extension-based MIME lookup; it is not a content validation API. */
    public function mimeType(path:String):String {
        requireFile(path);
        var extension = Path.extension(path).toLowerCase();
        return hx.well.handler.PublicHandler.contentType.get(extension) ?? "application/octet-stream";
    }

    public function getVisibility(path:String):String {
        var absolute = this.path(path);
        if (!FileSystem.exists(absolute)) throw new StorageException("get visibility", path);
        return (FileSystem.stat(absolute).mode & 63) != 0 ? "public" : "private";
    }

    public function setVisibility(path:String, visibility:String):Void {
        var absolute = this.path(path);
        if (!FileSystem.exists(absolute)) throw new StorageException("set visibility", path);
        LocalPermissions.set(absolute, visibility, FileSystem.isDirectory(absolute));
    }

    function listing(directory:String, recursive:Bool, wantDirectories:Bool):Array<String> {
        var absolute = this.path(directory);
        var result:Array<String> = [];
        if (!FileSystem.exists(absolute)) return result;
        if (!FileSystem.isDirectory(absolute)) throw new StorageException("list directory", directory);
        for (name in FileSystem.readDirectory(absolute)) {
            var relative = directory == "" ? name : directory + "/" + name;
            var child = this.path(relative);
            var isDirectory = FileSystem.isDirectory(child);
            if (isDirectory == wantDirectories) result.push(relative);
            if (recursive && isDirectory) result = result.concat(listing(relative, true, wantDirectories));
        }
        result.sort(Reflect.compare);
        return result;
    }

    public function files(directory:String, recursive:Bool):Array<String> {
        return listing(StoragePath.normalize(directory), recursive, false);
    }

    public function directories(directory:String, recursive:Bool):Array<String> {
        return listing(StoragePath.normalize(directory), recursive, true);
    }

    public function makeDirectory(path:String):Void {
        createParents(this.path(path));
    }

    public function deleteDirectory(path:String):Void {
        var absolute = this.path(path);
        if (!FileSystem.exists(absolute)) return;
        if (!FileSystem.isDirectory(absolute)) throw new StorageException("delete directory", path);
        // Validate the entire tree before deleting anything, including links in
        // directories that would otherwise be followed by recursive deletion.
        listing(path, true, true);
        removeDirectory(path);
    }

    function removeDirectory(path:String):Void {
        var absolute = this.path(path);
        for (name in FileSystem.readDirectory(absolute)) {
            var relative = path == "" ? name : path + "/" + name;
            if (FileSystem.isDirectory(this.path(relative))) removeDirectory(relative);
            else delete(relative);
        }
        // Keep the configured root usable after deleting its contents.
        if (path != "") FileSystem.deleteDirectory(absolute);
    }
}
