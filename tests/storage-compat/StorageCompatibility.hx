import hx.well.facades.Config;
import hx.well.facades.Environment;
import hx.well.facades.Storage;
import hx.well.config.ConfigData;

class StorageCompatibility {
    static function main() {
        Environment.reset();
        ConfigData.init();
        var root = Sys.args()[0];
        Config.set("filesystems.default_disk", "local");
        Config.set("filesystems.disks", [
            "local" => {driver: "local", root: root, url: "https://files.example.test/storage", throw_errors: false},
            "scoped" => {driver: "scoped", disk: "local", prefix: "tenants/one"},
            "readonly" => {driver: "local", root: root, read_only: true, throw_errors: false}
        ]);
        var disk = Storage.disk();
        var result:Dynamic = {};
        result.text = {
            put: Storage.put("notes.txt", "middle"),
            prepend: Storage.prepend("notes.txt", "first", "|"),
            append: Storage.append("notes.txt", "last", "|"),
            content: Storage.get("notes.txt"),
            size: Storage.size("notes.txt"),
            exists: Storage.exists("notes.txt"),
            missing: Storage.missing("absent.txt"),
            absent: Storage.get("absent.txt")
        };
        disk.put("empty.txt", "");
        disk.append("empty.txt", "line", "|");
        result.empty_append = disk.get("empty.txt");
        disk.put("orders.json", '{"id":42,"items":["one","two"]}');
        result.json = disk.json("orders.json");
        disk.put("invalid.json", "{");
        result.invalid_json = disk.json("invalid.json");
        var bytes = haxe.io.Bytes.ofHex("0001ff807f0d0a00");
        var source = new haxe.io.BytesInput(bytes);
        result.stream_write = disk.writeStream("binary.bin", source);
        source.close();
        var input = disk.readStream("binary.bin");
        result.stream_hex = input.readAll().toHex();
        input.close();
        result.checksum = disk.checksum("binary.bin");
        result.copy = disk.copy("notes.txt", "copies/first.txt");
        result.move = disk.move("copies/first.txt", "archive/final.txt");
        result.original_missing = disk.missing("copies/first.txt");
        disk.makeDirectory("empty-dir");
        disk.put("archive/sub/nested.txt", "nested");
        result.files = disk.files();
        result.all_files = disk.allFiles();
        result.directory_files = disk.allFiles("archive");
        result.directories = disk.directories();
        result.all_directories = disk.allDirectories();
        result.directory_checks = [disk.exists("empty-dir"), disk.directoryExists("empty-dir"), disk.fileExists("empty-dir")];
        disk.put("private.txt", "private", "private");
        disk.put("public.txt", "public", "public");
        result.visibility = [disk.getVisibility("private.txt"), disk.getVisibility("public.txt")];
        result.set_visibility = disk.setVisibility("private.txt", "public");
        result.changed_visibility = disk.getVisibility("private.txt");
        result.metadata = {
            size: disk.size("binary.bin"),
            modified_in_seconds: disk.lastModified("binary.bin") > Date.now().getTime() / 1000 - 60,
            text_mime: disk.mimeType("notes.txt"),
            json_mime: disk.mimeType("orders.json")
        };
        result.url = disk.url("folder/file.txt");
        var scoped = Storage.disk("scoped");
        result.scoped = {
            put: scoped.put("sub/file.txt", "scoped"),
            content: scoped.get("sub/file.txt"),
            parent_content: disk.get("tenants/one/sub/file.txt"),
            files: scoped.allFiles(),
            directories: scoped.allDirectories(),
            url: scoped.url("sub/file.txt")
        };
        var readOnly = Storage.disk("readonly");
        result.readonly = {
            content: readOnly.get("notes.txt"),
            put: readOnly.put("blocked.txt", "blocked"),
            delete: readOnly.delete("notes.txt"),
            copy: readOnly.copy("notes.txt", "blocked-copy.txt"),
            move: readOnly.move("notes.txt", "blocked-move.txt"),
            mkdir: readOnly.makeDirectory("blocked-dir"),
            rmdir: readOnly.deleteDirectory("archive"),
            visibility: readOnly.setVisibility("notes.txt", "public")
        };
        result.delete_many = disk.delete(["notes.txt", "missing.txt"]);
        result.deleted_missing = disk.missing("notes.txt");
        result.delete_directory = disk.deleteDirectory("archive");
        result.deleted_directory_missing = disk.directoryMissing("archive");
        result.delete_absent_directory = disk.deleteDirectory("absent-dir");
        result.failed_copy = disk.copy("missing.txt", "failed-copy.txt");
        Sys.println(haxe.Json.stringify(result));
    }
}
