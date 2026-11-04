package hx.well.storage;

/** Invalid paths are programming/security errors and are never silently ignored. */
class InvalidStoragePath extends StorageException {
    public function new(path:String) {
        super("path validation", path);
    }
}
