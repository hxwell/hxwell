package hx.well.config;

import hx.well.facades.Environment.env;
import hx.well.storage.StorageDiskConfig;

class FilesystemsConfig implements IConfig {
    public function new() {}

    public var default_disk:String = env("FILESYSTEM_DISK", "local");
    public var disks:Map<String, StorageDiskConfig> = [
        "local" => {
            driver: "local", root: "storage/app/private", visibility: "private", throw_errors: false
        },
        "public" => {
            driver: "local", root: "storage/app/public", url: env("APP_URL", "") + "/storage",
            visibility: "public", directory_visibility: "public", throw_errors: false
        }
    ];
}
