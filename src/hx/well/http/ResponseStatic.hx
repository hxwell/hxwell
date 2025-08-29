package hx.well.http;
import haxe.ThreadLocal;
import hx.well.exception.AbortException;
import haxe.ds.StringMap;
import haxe.extern.EitherType;

@:access(hx.well.exception.AbortException)
@:allow(hx.well.http.HttpHandler)
@:allow(hx.well.http.driver.AbstractHttpDriver)
class ResponseStatic {
    private static var threadLocal:ThreadLocal<Response> = new ThreadLocal();
    private static var responseCodes:Map<Int, String> = [
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        103 => "Early Hints",
        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        218 => "This is fine",
        226 => "IM Used",
        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        306 => "Switch Proxy",
        307 => "Temporary Redirect",
        308 => "Resume Incomplete",
        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Request Entity Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        418 => "I'm a teapot",
        419 => "Page Expired",
        420 => "Method Failure",
        421 => "Misdirected Request",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",
        428 => "Precondition Required",
        429 => "Too Many Requests",
        431 => "Request Header Fields Too Large",
        440 => "Login Time-out",
        444 => "Connection Closed Without Response",
        449 => "Retry With",
        450 => "Blocked by Windows Parental Controls",
        451 => "Unavailable For Legal Reasons",
        494 => "Request Header Too Large",
        495 => "SSL Certificate Error",
        496 => "SSL Certificate Required",
        497 => "HTTP Request Sent to HTTPS Port",
        498 => "Invalid Token (Esri)",
        499 => "Client Closed Request",
        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        506 => "Variant Also Negotiates",
        507 => "Insufficient Storage",
        508 => "Loop Detected",
        509 => "Bandwidth Limit Exceeded",
        510 => "Not Extended",
        511 => "Network Authentication Required",
        520 => "Unknown Error",
        521 => "Web Server Is Down",
        522 => "Connection Timed Out",
        523 => "Origin Is Unreachable",
        524 => "A Timeout Occurred",
        525 => "SSL Handshake Failed",
        526 => "Invalid SSL Certificate",
        527 => "Railgun Listener to Origin Error",
        530 => "Origin DNS Error",
        598 => "Network Read Timeout Error"
    ];

    public static function reset():Void {
        threadLocal.set(new Response());
    }

    public static function set(response:Response):Void {
        threadLocal.set(response);
    }

    public static function get():Response {
        return threadLocal.get();
    }

    public static function header(key:String, value:String):Response {
        var response:Response = threadLocal.get();
        if(value == null)
            response.headers.remove(key)
        else
            response.headers.set(key, value);
        return response;
    }

    public static function cookie(key:String, value:String, encrypt:Bool = false):Null<CookieBuilder<Response>> {
        var response:Response = threadLocal.get();
        if(value == null)
        {
            response.cookies.remove(key);
            return null;
        }
        else
        {
            var cookieData:CookieData = new CookieData(key, value);
            cookieData.encrypt = encrypt;
            response.cookies.set(key, cookieData);
            return new CookieBuilder<Response>(threadLocal.get(), cookieData);
        }
    }

    public static function cookieFromData(key:String, value:CookieData):Response {
        var response:Response = threadLocal.get();
        if(value == null)
        {
            response.cookies.remove(key);
            return null;
        }
        else
        {
            response.cookies.set(key, value);
            return threadLocal.get();
        }
    }

    public static function redirect(url:String, statusCode:Null<Int> = null):EitherType<AbstractResponse, Void> {
        return ResponseBuilder.asRedirect(url, statusCode);
    }

    public static inline function abort(code:Int, ?status:String):Void
    {
        throw new AbortException(code, status);
    }

    public static function getStatusMessage(code:Int):String {
        return responseCodes.exists(code) ? responseCodes.get(code) : "OK";
    }
}