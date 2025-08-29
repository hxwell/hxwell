package hx.well.handler;
import hx.well.http.Request;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import hx.well.http.AbstractResponse;
import hx.well.http.FileInputResponse;
import hx.well.facades.Config;
using StringTools;
import hx.well.http.ResponseStatic.abort;

class PublicHandler extends AbstractHandler {
    // TODO: Make this configurable
    public static var contentType:Map<String, String> = [
        "html" => "text/html",
        "css" => "text/css",
        "js" => "text/javascript",
        "json" => "application/json",
        "png" => "image/png",
        "jpg" => "image/jpeg",
        "jpeg" => "image/jpeg",
        "ico" => "image/x-icon",
        "svg" => "image/svg+xml",
        "ttf" => "font/ttf",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "eot" => "font/eot",
        "otf" => "font/otf",
        // Add more content types as needed
        "mp3" => "audio/mpeg",
        "wav" => "audio/wav",
        "mp4" => "video/mp4",
        "webm" => "video/webm",
        "pdf" => "application/pdf",
        "zip" => "application/zip",
        "tar" => "application/x-tar",
        "gz" => "application/gzip",
        "bz2" => "application/x-bzip2",
        "7z" => "application/x-7z-compressed",
        "rar" => "application/x-rar-compressed",
        "doc" => "application/msword",
        "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls" => "application/vnd.ms-excel",
        "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt" => "application/vnd.ms-powerpoint",
        "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "txt" => "text/plain",
        "xml" => "application/xml",
        "csv" => "text/csv",
        "jsonld" => "application/ld+json",
        "rss" => "application/rss+xml",
        "atom" => "application/atom+xml",
        "xhtml" => "application/xhtml+xml",
        "webp" => "image/webp",
        "avif" => "image/avif",
        "flac" => "audio/flac",
        "ogg" => "audio/ogg",
        "mkv" => "video/x-matroska",
        "mov" => "video/quicktime",
        "avi" => "video/x-msvideo",
        "m3u8" => "application/vnd.apple.mpegurl",
        "ts" => "video/mp2t",
        "wasm" => "application/wasm",
        "webmanifest" => "application/manifest+json",
        "map" => "application/json",
        "md" => "text/markdown",
        "yaml" => "application/x-yaml",
        "yml" => "application/x-yaml",
        "svgz" => "image/svg+xml",
        "ejs" => "text/html",
        "vue" => "text/x-template",
        "scss" => "text/x-scss",
        "less" => "text/x-less",
        "styl" => "text/stylus",
    ];

    public function new():Void {
        super();
    }

    public function execute(request:Request):AbstractResponse {
        var requestPath:String = Path.normalize(request.path);

        // Traversal attack?
        var publicPath:String = Path.normalize(Config.get("http.public_path"));
        var filePath:String = Path.normalize('${publicPath}/${requestPath}');
        if(!filePath.startsWith(publicPath)) {
            abort(500);
        }

        if(FileSystem.exists(filePath) && FileSystem.isDirectory(filePath)) {
            filePath += "/index.html";
        }

        if(FileSystem.exists(filePath) && !FileSystem.isDirectory(filePath))
        {
            var fileInput = File.read(filePath);

            try {
                var fileInputResponse:FileInputResponse = new FileInputResponse(fileInput);
                var contentType:String = resolveContentType(filePath);
                if(contentType != null)
                    fileInputResponse.header("Content-Type", contentType);

                return fileInputResponse;
            } catch (e) {
                fileInput.close();
                throw e;
            }
        }

        abort(404);
        return null;
    }

    public function resolveContentType(path:String):String {
        var fileExtension = path.substring(path.lastIndexOf(".") + 1);
        return contentType.get(fileExtension) ?? "application/octet-stream";
    }
}