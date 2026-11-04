package cases;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import hx.well.facades.Config;
import hx.well.facades.Storage;
import hx.well.storage.InvalidStoragePath;
import hx.well.storage.LocalStorageAdapter;
import hx.well.storage.StorageDisk;
import hx.well.storage.StorageDiskConfig;
import hx.well.storage.StorageException;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;

class TestStorage extends utest.Test {
    var fixture:SecurityFixture;
    var disk:StorageDisk;
    var originalDefault:String;
    var originalDisks:Map<String, StorageDiskConfig>;

    function setup() {
        fixture = new SecurityFixture();
        originalDefault = Config.get("filesystems.default_disk");
        originalDisks = Config.get("filesystems.disks");
        Config.set("filesystems.default_disk", "storage-test");
        Config.set("filesystems.disks", [
            "storage-test" => {driver: "local", root: fixture.root + "/storage", url: "https://files.example.test/storage", throw_errors: true},
            "storage-scope" => {driver: "scoped", disk: "storage-test", prefix: "tenant/one", throw_errors: true},
            "storage-nested" => {driver: "scoped", disk: "storage-scope", prefix: "nested"},
            "storage-readonly" => {driver: "local", root: fixture.root + "/storage", read_only: true, throw_errors: false},
            "storage-cycle" => {driver: "scoped", disk: "storage-cycle", prefix: "loop"}
        ]);
        disk = Storage.disk();
    }

    function teardown() {
        for (name in ["storage-test", "storage-scope", "storage-nested", "storage-readonly", "storage-cycle", "storage-fake", "storage-custom"])
            Storage.forgetDisk(name);
        Config.set("filesystems.default_disk", originalDefault);
        Config.set("filesystems.disks", originalDisks);
        fixture.close();
    }

    function testFacadeAndNamedDiskResolution() {
        Assert.equals(disk, Storage.disk("storage-test"));
        Assert.equals(disk, Storage.drive());
        Assert.equals("storage-test", Storage.getDefaultDriver());
        Assert.isTrue(Storage.put("default.txt", "default disk"));
        Assert.equals("default disk", disk.get("default.txt"));
        Assert.isTrue(Storage.exists("default.txt"));
        Assert.raises(() -> Storage.disk("unknown"), haxe.Exception);
        Assert.raises(() -> Storage.build({driver: "unknown"}), haxe.Exception);
        Assert.raises(() -> Storage.build({driver: "local"}), haxe.Exception);
        Storage.forgetDisk("storage-test");
        Assert.notEquals(disk, Storage.disk());
        Assert.equals("default disk", Storage.get("default.txt"));
    }

    function testTextBinaryJsonAndMetadata() {
        Assert.isTrue(disk.put("nested/text.txt", "merhaba dünya"));
        Assert.equals("merhaba dünya", disk.get("nested/text.txt"));
        Assert.equals(Bytes.ofString("merhaba dünya").length, disk.size("nested/text.txt"));
        Assert.isTrue(disk.lastModified("nested/text.txt") <= Date.now().getTime() / 1000);
        Assert.isTrue(disk.lastModified("nested/text.txt") > Date.now().getTime() / 1000 - 60);
        var bytes = Bytes.ofHex("0001ff807f0d0a00");
        Assert.isTrue(disk.put("nested/data.bin", bytes));
        Assert.equals(bytes.toHex(), disk.getBytes("nested/data.bin").toHex());
        Assert.isTrue(disk.put("orders.json", '{"id":42,"items":["one","two"]}'));
        Assert.equals(42, disk.json("orders.json").id);
        Assert.equals("application/json", disk.mimeType("orders.json"));
        Assert.equals("text/plain", disk.mimeType("nested/text.txt"));
        Assert.equals("application/octet-stream", disk.mimeType("nested/data.bin"));
        Assert.equals(haxe.crypto.Md5.make(bytes).toHex(), disk.checksum("nested/data.bin"));
        Assert.equals(haxe.crypto.Sha256.make(bytes).toHex(), disk.checksum("nested/data.bin", "sha256"));
        Assert.raises(() -> disk.checksum("orders.json", "unknown"), haxe.Exception);
        disk.put("invalid.json", "{");
        Assert.isNull(disk.json("invalid.json"));
    }

    function testStreamingOwnershipAndFailedWritesPreserveDestination() {
        var input = new TrackedStorageInput(Bytes.ofString("streamed contents"));
        Assert.isTrue(disk.put("stream.txt", input));
        Assert.isFalse(input.closed);
        input.close();
        var read = disk.readStream("stream.txt");
        Assert.equals("streamed contents", read.readAll().toString());
        read.close();
        var broken = new BrokenStorageInput();
        Assert.raises(() -> disk.writeStream("stream.txt", broken), StorageException);
        Assert.isFalse(broken.closed);
        Assert.equals("streamed contents", disk.get("stream.txt"));
        Assert.same(["stream.txt"], disk.allFiles());
        broken.close();
    }

    function testAppendPrependCopyMoveAndDelete() {
        Assert.isTrue(disk.append("lines.txt", "middle", "|"));
        Assert.isTrue(disk.prepend("lines.txt", "first", "|"));
        Assert.isTrue(disk.append("lines.txt", "last", "|"));
        Assert.equals("first|middle|last", disk.get("lines.txt"));
        disk.put("empty.txt", "");
        Assert.isTrue(disk.append("empty.txt", "line", "|"));
        Assert.equals("|line", disk.get("empty.txt"));
        Assert.isTrue(disk.copy("lines.txt", "copies/one.txt"));
        disk.put("moved/final.txt", "overwritten");
        Assert.isTrue(disk.move("copies/one.txt", "moved/final.txt"));
        Assert.isTrue(disk.missing("copies/one.txt"));
        Assert.equals("first|middle|last", disk.get("moved/final.txt"));
        Assert.isTrue(disk.copy("lines.txt", "lines.txt"));
        Assert.isTrue(disk.move("lines.txt", "lines.txt"));
        Assert.isTrue(disk.delete(["lines.txt", "moved/final.txt", "never-existed"]));
        Assert.isTrue(disk.missing("lines.txt"));
        Assert.isTrue(disk.directoryExists("moved"));
        Assert.raises(() -> disk.delete("moved"), StorageException);
    }

    function testDirectoryListingUsesDiskRelativeSortedPaths() {
        disk.makeDirectory("empty");
        disk.put("z.txt", "z");
        disk.put("a/one.txt", "one");
        disk.put("a/sub/two.txt", "two");
        Assert.same(["z.txt"], disk.files());
        Assert.same(["a/one.txt", "a/sub/two.txt", "z.txt"], disk.allFiles());
        Assert.same(["a", "empty"], disk.directories());
        Assert.same(["a", "a/sub", "empty"], disk.allDirectories());
        Assert.same(["a/one.txt", "a/sub/two.txt"], disk.allFiles("a"));
        Assert.same([], disk.files("missing"));
        Assert.isTrue(disk.directoryMissing("missing"));
        Assert.isTrue(disk.exists("empty"));
        Assert.isTrue(disk.fileMissing("empty"));
        Assert.equals(disk, disk.assertDirectoryEmpty("empty").assertCount("", 1).assertCount("", 3, true));
        Assert.isTrue(disk.deleteDirectory("a"));
        Assert.isTrue(disk.directoryMissing("a"));
        Assert.isTrue(disk.deleteDirectory("never-existed"));
        Assert.isTrue(disk.deleteDirectory(""));
        Assert.same([], disk.allFiles());
        Assert.isTrue(disk.directoryExists(""));
    }

    function testRealPermissionsAndVisibility() {
        disk.put("private.txt", "secret");
        Assert.equals("private", disk.getVisibility("private.txt"));
        Assert.equals(384, FileSystem.stat(disk.path("private.txt")).mode & 511);
        Assert.equals(448, FileSystem.stat(disk.path("")).mode & 511);
        Assert.isTrue(disk.setVisibility("private.txt", "public"));
        Assert.equals("public", disk.getVisibility("private.txt"));
        Assert.equals(420, FileSystem.stat(disk.path("private.txt")).mode & 511);
        disk.put("public.txt", "public", "public");
        disk.put("options.txt", "options", {visibility: "public"});
        Assert.equals("public", disk.getVisibility("public.txt"));
        Assert.equals("public", disk.getVisibility("options.txt"));
        Assert.raises(() -> disk.setVisibility("public.txt", "invalid"), haxe.Exception);
        Assert.raises(() -> disk.put("public.txt", "no mutation", "invalid"), haxe.Exception);
        Assert.equals("public", disk.get("public.txt"));
    }

    function testFailureModesAndReadOnlyDisks() {
        var quiet = Storage.build({driver: "local", root: fixture.root + "/storage", throw_errors: false});
        Assert.isNull(quiet.get("missing.txt"));
        Assert.isNull(quiet.readStream("missing.txt"));
        Assert.isNull(quiet.mimeType("missing.txt"));
        Assert.isNull(quiet.checksum("missing.txt"));
        Assert.isFalse(quiet.copy("missing.txt", "copy.txt"));
        Assert.isFalse(quiet.move("missing.txt", "moved.txt"));
        Assert.raises(() -> disk.get("missing.txt"), StorageException);
        Assert.raises(() -> quiet.size("missing.txt"), StorageException);
        disk.put("original.txt", "unchanged");
        disk.makeDirectory("dir");
        var readOnly = Storage.disk("storage-readonly");
        Assert.equals("unchanged", readOnly.get("original.txt"));
        Assert.isFalse(readOnly.put("original.txt", "changed"));
        Assert.isFalse(readOnly.append("original.txt", "changed"));
        Assert.isFalse(readOnly.prepend("original.txt", "changed"));
        Assert.isFalse(readOnly.writeStream("new.txt", new BytesInput(Bytes.ofString("changed"))));
        Assert.isFalse(readOnly.copy("original.txt", "copy.txt"));
        Assert.isFalse(readOnly.move("original.txt", "moved.txt"));
        Assert.isFalse(readOnly.delete("original.txt"));
        Assert.isFalse(readOnly.makeDirectory("new-dir"));
        Assert.isFalse(readOnly.deleteDirectory("dir"));
        Assert.isFalse(readOnly.setVisibility("original.txt", "public"));
        Assert.isNull(readOnly.putFileAs("", disk.path("original.txt"), "copy.txt"));
        Assert.equals("unchanged", disk.get("original.txt"));
        Assert.isTrue(disk.directoryExists("dir"));
        Assert.same(["original.txt"], disk.allFiles());
        var strict = Storage.build({driver: "local", root: fixture.root + "/storage", read_only: true, throw_errors: true});
        Assert.raises(() -> strict.put("no.txt", "no"), StorageException);
    }

    function testScopedDisksCannotEscapeTheirPrefix() {
        var scoped = Storage.disk("storage-scope");
        Assert.isTrue(scoped.put("documents/report.txt", "tenant one"));
        Assert.equals("tenant one", disk.get("tenant/one/documents/report.txt"));
        Assert.same(["documents/report.txt"], scoped.allFiles());
        Assert.same(["documents"], scoped.allDirectories());
        Assert.equals("https://files.example.test/storage/tenant/one/documents/report.txt", scoped.url("documents/report.txt"));
        Assert.raises(() -> scoped.put("../two.txt", "escaped"), InvalidStoragePath);
        Storage.disk("storage-nested").put("file.txt", "nested");
        Assert.equals("nested", disk.get("tenant/one/nested/file.txt"));
        Assert.raises(() -> Storage.disk("storage-cycle"), haxe.Exception);
        Assert.isTrue(scoped.deleteDirectory(""));
        Assert.isTrue(disk.missing("tenant/one"));
    }

    function testNormalizationAndUnsafePathsAreNeverSilentlyIgnored() {
        Assert.isTrue(disk.put("/one/./sub/../file.txt", "safe"));
        Assert.isTrue(disk.put("one\\other.txt", "other"));
        Assert.equals("safe", disk.get("one/file.txt"));
        var quiet = Storage.build({driver: "local", root: fixture.root + "/storage"});
        for (path in ["../outside", "a/../../outside", "C:/absolute", "file:stream", "bad\x00name", "bad\nname"]) {
            var unsafe = path;
            Assert.raises(() -> quiet.put(unsafe, "bad"), InvalidStoragePath);
            Assert.raises(() -> quiet.get(unsafe), InvalidStoragePath);
            Assert.raises(() -> quiet.delete(unsafe), InvalidStoragePath);
            Assert.raises(() -> quiet.deleteDirectory(unsafe), InvalidStoragePath);
            Assert.raises(() -> quiet.url(unsafe), InvalidStoragePath);
        }
        Assert.raises(() -> disk.put("", "bad"), InvalidStoragePath);
        Assert.raises(() -> disk.delete(""), InvalidStoragePath);
        Assert.raises(() -> disk.delete(["one/file.txt", "../outside"]), InvalidStoragePath);
        Assert.isTrue(disk.exists("one/file.txt"));
    }

    function testSymlinksAndDanglingLinksAreRejectedForEveryOperation() {
        disk.put("safe/file.txt", "inside");
        File.saveContent(fixture.root + "/outside.txt", "outside");
        FileSystem.createDirectory(fixture.root + "/outside-dir");
        File.saveContent(fixture.root + "/outside-dir/private.txt", "outside-directory");
        fixture.symlink(fixture.root + "/outside.txt", disk.path("linked.txt"));
        fixture.symlink(fixture.root + "/outside-dir", disk.path("linked-dir"));
        fixture.symlink(fixture.root + "/absent.txt", disk.path("dangling.txt"));
        fixture.symlink(disk.path("safe"), disk.path("internal-link"));
        var quiet = Storage.build({driver: "local", root: fixture.root + "/storage"});
        for (path in ["linked.txt", "linked-dir/private.txt", "dangling.txt", "internal-link/file.txt"]) {
            var unsafe = path;
            Assert.raises(() -> quiet.get(unsafe), InvalidStoragePath);
            Assert.raises(() -> quiet.put(unsafe, "bad"), InvalidStoragePath);
            Assert.raises(() -> quiet.copy("safe/file.txt", unsafe), InvalidStoragePath);
            Assert.raises(() -> quiet.move("safe/file.txt", unsafe), InvalidStoragePath);
        }
        Assert.raises(() -> quiet.put("linked-dir/missing/new.txt", "bad"), InvalidStoragePath);
        Assert.raises(() -> quiet.makeDirectory("linked-dir/new"), InvalidStoragePath);
        Assert.raises(() -> quiet.deleteDirectory("linked-dir"), InvalidStoragePath);
        Assert.raises(() -> quiet.allFiles(), InvalidStoragePath);
        Assert.raises(() -> quiet.deleteDirectory(""), InvalidStoragePath);
        Assert.equals("outside", File.getContent(fixture.root + "/outside.txt"));
        Assert.equals("outside-directory", File.getContent(fixture.root + "/outside-dir/private.txt"));
        Assert.isTrue(disk.exists("safe/file.txt"));
        Assert.isFalse(FileSystem.exists(fixture.root + "/absent.txt"));
    }

    function testFileStorageAndDownloadResponses() {
        var source = fixture.root + "/source.bin";
        var bytes = Bytes.ofHex("00ff01020380");
        File.saveBytes(source, bytes);
        Assert.equals("uploads/custom.bin", disk.putFileAs("uploads", source, "custom.bin"));
        var generated = disk.putFile("uploads", source);
        Assert.isTrue(~/^uploads\/[A-Za-z0-9_-]{40}\.bin$/.match(generated));
        Assert.equals(bytes.toHex(), disk.getBytes(generated).toHex());
        var response = disk.download("uploads/custom.bin", "rapor ü.bin", ["X-Storage" => "yes"]);
        Assert.equals(bytes.length, haxe.Int64.toInt(response.contentLength));
        Assert.equals(bytes.toHex(), response.toInput().readAll().toHex());
        Assert.equals("yes", @:privateAccess response.headers.get("X-Storage"));
        Assert.equals("application/octet-stream", @:privateAccess response.headers.get("Content-Type"));
        Assert.isTrue(StringTools.startsWith(@:privateAccess response.headers.get("Content-Disposition"), "attachment;"));
        Assert.isTrue((@:privateAccess response.headers.get("Content-Disposition")).indexOf("filename*=UTF-8''rapor%20%C3%BC.bin") >= 0);
        response.dispose();
        var inlineResponse = disk.response("uploads/custom.bin");
        Assert.isTrue(StringTools.startsWith(@:privateAccess inlineResponse.headers.get("Content-Disposition"), "inline;"));
        inlineResponse.dispose();
        Assert.raises(() -> disk.download("uploads/custom.bin", "bad\r\nX-Test: yes"), haxe.Exception);
        Assert.raises(() -> disk.download("uploads/custom.bin", "bad/path"), haxe.Exception);
        Assert.raises(() -> disk.download("uploads/custom.bin", null, ["X-Test" => "bad\r\nheader"]), haxe.Exception);
        Assert.raises(() -> disk.download("uploads/custom.bin", null, ["Content-Length" => "999"]), haxe.Exception);
    }

    function testUrlsAndTemporaryUrlCallback() {
        Assert.equals("https://files.example.test/storage/folder/a%20b%23%3F.txt", disk.url("folder/a b#?.txt"));
        Assert.equals("https://files.example.test/storage/%252e%252e/file.txt", disk.url("%2e%2e/file.txt"));
        Assert.isFalse(disk.providesTemporaryUrls());
        Assert.raises(() -> disk.temporaryUrl("file.txt", Date.now()), haxe.Exception);
        var expires = Date.fromTime(Date.now().getTime() + 60000);
        disk.buildTemporaryUrlsUsing((path, expiration, options) -> {
            Assert.equals("file.txt", path);
            Assert.equals(expires.getTime(), expiration.getTime());
            Assert.equals("attachment", options.get("disposition"));
            return "https://signed.example.test/file";
        });
        Assert.isTrue(disk.providesTemporaryUrls());
        Assert.equals("https://signed.example.test/file", disk.temporaryUrl("file.txt", expires, ["disposition" => "attachment"]));
        var noUrl = Storage.build({driver: "local", root: fixture.root + "/private"});
        Assert.raises(() -> noUrl.url("file.txt"), haxe.Exception);
    }

    function testDownloadLengthMatchesTheOpenedFileDuringAtomicReplacement() {
        for (beforeOpen in [true, false]) {
            var config:StorageDiskConfig = {driver: "local", root: fixture.root + "/snapshot-" + beforeOpen, throw_errors: true};
            var adapter = new ReplacingStorageAdapter(config, beforeOpen);
            var storage = new StorageDisk(adapter, config);
            storage.put("download.txt", "old");
            var response = storage.download("download.txt");
            var expected = beforeOpen ? ReplacingStorageAdapter.replacement : "old";
            Assert.equals(Bytes.ofString(expected).length, haxe.Int64.toInt(response.contentLength));
            Assert.equals(expected, response.toInput().readAll().toString());
            response.dispose();
            Assert.equals(ReplacingStorageAdapter.replacement, File.getContent(adapter.path("download.txt")));
        }
    }

    function testFakeAssertionsAndCustomAdapterRegistration() {
        disk.put("live.txt", "keep");
        var fake = Storage.fake("storage-fake", fixture.root);
        Assert.equals(fake, Storage.disk("storage-fake"));
        fake.assertDirectoryEmpty("");
        fake.put("photo.jpg", "test");
        Assert.equals(fake, fake.assertExists("photo.jpg", "test").assertMissing(["other.jpg"]));
        Assert.raises(() -> fake.assertMissing("photo.jpg"), haxe.Exception);
        Assert.raises(() -> fake.assertExists("photo.jpg", "wrong"), haxe.Exception);
        Assert.raises(() -> fake.assertCount("", 2), haxe.Exception);
        Assert.raises(() -> fake.assertDirectoryEmpty(""), haxe.Exception);
        var second = Storage.fake("storage-fake", fixture.root);
        Assert.notEquals(fake.path(""), second.path(""));
        Assert.isTrue(fake.exists("photo.jpg"));
        Assert.equals("keep", disk.get("live.txt"));
        var defaultFake = Storage.fake(null, fixture.root);
        Storage.put("default-fake.txt", "isolated");
        Assert.equals(defaultFake, Storage.assertExists("default-fake.txt", "isolated").assertCount("", 1));
        Assert.equals(defaultFake, Storage.assertMissing("live.txt"));
        Storage.delete("default-fake.txt");
        Assert.equals(defaultFake, Storage.assertDirectoryEmpty(""));
        Assert.equals("keep", disk.get("live.txt"));
        Storage.extend("storage-custom", config -> new LocalStorageAdapter(config));
        var custom = Storage.build({driver: "storage-custom", root: fixture.root + "/custom", throw_errors: true});
        Storage.set("storage-custom", custom);
        Assert.isTrue(Storage.disk("storage-custom").put("works.txt", "custom"));
        Assert.equals("custom", custom.get("works.txt"));
        Storage.purge("storage-custom");
        Assert.raises(() -> Storage.disk("storage-custom"), haxe.Exception);
    }
}

private class TrackedStorageInput extends BytesInput {
    public var closed:Bool = false;
    override public function close():Void { closed = true; super.close(); }
}

private class BrokenStorageInput extends haxe.io.Input {
    public var closed:Bool = false;
    public function new() {}
    override public function readByte():Int { throw new haxe.Exception("Simulated source read failure"); }
    override public function close():Void { closed = true; }
}

/** Deterministically replace the path on either side of opening its descriptor. */
private class ReplacingStorageAdapter extends LocalStorageAdapter {
    public static inline var replacement = "a longer replacement file";
    var beforeOpen:Bool;

    public function new(config:StorageDiskConfig, beforeOpen:Bool) {
        super(config);
        this.beforeOpen = beforeOpen;
    }

    override public function readStream(path:String):haxe.io.Input {
        if (beforeOpen) replace(path);
        var input = super.readStream(path);
        try {
            if (!beforeOpen) replace(path);
            return input;
        } catch (e:Dynamic) {
            input.close();
            throw e;
        }
    }

    function replace(path:String):Void {
        var input = new BytesInput(Bytes.ofString(replacement));
        try super.writeStream(path, input) catch (e:Dynamic) {
            input.close();
            throw e;
        }
        input.close();
    }
}
