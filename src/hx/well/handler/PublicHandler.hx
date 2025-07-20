package hx.well.handler;
import hx.well.http.Request;
import sys.net.Socket;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import hx.well.http.AbstractResponse;
import hx.well.http.FileInputResponse;
import hx.well.facades.Config;
using StringTools;
import hx.well.http.ResponseStatic.abort;

class PublicHandler extends AbstractHandler {
    public function new():Void {
        super();
    }

    public function execute(request:Request):AbstractResponse {
        var requestPath:String = Path.normalize(request.path);

        trace(requestPath);

        // Traversal attack?
        var publicPath:String = Path.normalize('${Config.get("public.path", "public")}');
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
                var contentType:String = contentType(filePath);
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

    public function contentType(path:String):String {
        var fileExtension = path.substring(path.lastIndexOf(".") + 1);
        switch (fileExtension)
        {
            case "html":
                return "text/html";
            case "css":
                return "text/css";
            case "js":
                return "text/javascript";
            case "json":
                return "application/json";
            case "png":
                return "image/png";
            case "jpg" | "jpeg":
                return "image/jpeg";
            case "ico":
                return "image/x-icon";
            case "svg":
                return "image/svg+xml";
            case "ttf":
                return "font/ttf";
            case "woff":
                return "font/woff";
            case "woff2":
                return "font/woff2";
            case "eot":
                return "font/eot";
            case "otf":
                return "font/otf";
            case "mp3":
                return "audio/mpeg";
            case "wav":
                return "audio/wav";
            case "mp4":
                return "video/mp4";
            case "webm":
                return "video/webm";
            case "pdf":
                return "application/pdf";
            case "zip":
                return "application/zip";
            case "tar":
                return "application/x-tar";
            case "gz":
                return "application/gzip";
            case "bz2":
                return "application/x-bzip2";
            case "7z":
                return "application/x-7z-compressed";
            case "rar":
                return "application/x-rar-compressed";
            case "doc":
                return "application/msword";
            case "docx":
                return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            case "xls":
                return "application/vnd.ms-excel";
            default:
                return "application/octet-stream";
        }
    }
}