package hx.well.http.driver.undertow;

#if java
import java.net.InetSocketAddress;
import java.lang.Runnable;
import java.util.Map;
import javax.net.ssl.SSLContext;
import java.lang.Integer;

@:native("io.undertow.Undertow")
extern class UndertowExtern {
    public extern static function builder():UndertowBuilderExtern;
    public extern function start():Void;
    public extern function stop():Void;
}

@:native("io.undertow.Undertow$Builder")
extern class UndertowBuilderExtern {
    public function addHttpListener(port:Int, host:String):UndertowBuilderExtern;
    public function addHttpsListener(port:Int, host:String, sslContext:SSLContext):UndertowBuilderExtern;
    public function setHandler(handler:HttpHandlerExtern):UndertowBuilderExtern;
    public function setServerOption<T>(option:Option<T>, value:T):UndertowBuilderExtern;
    public function setSocketOption<T>(option:Option<T>, value:T):UndertowBuilderExtern;
    public function setWorkerOption<T>(option:Option<T>, value:T):UndertowBuilderExtern;
    public function build():UndertowExtern;
}

@:native("io.undertow.server.HttpHandler")
extern interface HttpHandlerExtern {
    public function handleRequest(exchange:HttpServerExchangeExtern):Void;
}

@:native("io.undertow.server.HttpServerExchange")
extern class HttpServerExchangeExtern {
    public function startBlocking():BlockingHttpExchangeExtern;
    public function dispatch(body:Job):HttpServerExchangeExtern;
    public function getRequestMethod():HttpStringExtern;
    public function getRequestPath():String;
    public function getResponseSender():SenderExtern;
    public function endExchange():Void;
    public function getInputStream():java.io.InputStream;
    public function getOutputStream():java.io.OutputStream;


    public function getSourceAddress():InetSocketAddress;
    public function	getHostName():String;
    public function getHostPort():Int;
    public function getQueryString():String;
    public function getRequestCookies():Map<String, ExternCookie>;
    public function getResponseCookies():Map<String, ExternCookie>;
    public function getRequestHeaders():HeaderMapExtern;
    public function getResponseHeaders():HeaderMapExtern;

    public function setStatusCode(statusCode:Int):HttpServerExchangeExtern;
}

@:native("io.undertow.util.HeaderMap")
extern class HeaderMapExtern {
    public function iterator():java.util.Iterator<HeaderValuesExtern>;
    public function add(headerName:HttpStringExtern, headerValue:String):HeaderMapExtern;
}

@:native("io.undertow.util.HeaderValues")
extern class HeaderValuesExtern {
    public function getFirst():String;
    public function getHeaderName():HttpStringExtern;
    public function iterator():java.util.Iterator<String>;
}

@:native("io.undertow.server.handlers.CookieImpl")
extern class ExternCookieImpl implements ExternCookie {
    public function new(key:String, value:String);

    public function getComment():String;
    public function getDomain():String;
    public function getExpires():Date;
    public function getMaxAge():Int;
    public function getName():String;
    public function getPath():String;
    public function getSameSiteMode():String;
    public function getValue():String;
    public function getVersion():String;
    public function isDiscard():Bool;
    public function isHttpOnly():Bool;
    public function isSameSite():Bool;
    public function isSecure():Bool;

    public function setComment(comment:String):ExternCookie;
    public function setDiscard(discard:Bool):ExternCookieImpl;
    public function setDomain(domain:String):ExternCookieImpl;
    public function setExpires(expires:Date):ExternCookieImpl;
    public function setHttpOnly(httpOnly:Bool):ExternCookieImpl;
    public function setMaxAge(maxAge:Integer):ExternCookieImpl;
    public function setPath(path:String):ExternCookieImpl;
    public function setSameSite(sameSite:Bool):ExternCookie;
    public function setSameSiteMode(mode:String):ExternCookie;
    public function setSecure(secure:Bool):ExternCookieImpl;
    public function setValue(value:String):ExternCookieImpl;
    public function setVerison(version:Integer):ExternCookieImpl;
}

@:native("io.undertow.server.handlers.Cookie")
extern interface ExternCookie {
    public function getComment():String;
    public function getDomain():String;
    public function getExpires():Date;
    public function getMaxAge():Int;
    public function getName():String;
    public function getPath():String;
    public function getSameSiteMode():String;
    public function getValue():String;
    public function getVersion():String;
    public function isDiscard():Bool;
    public function isHttpOnly():Bool;
    public function isSameSite():Bool;
    public function isSecure():Bool;

    public function setComment(comment:String):ExternCookie;
    public function setDiscard(discard:Bool):ExternCookie;
    public function setDomain(domain:String):ExternCookie;
    public function setExpires(expires:Date):ExternCookie;
    public function setHttpOnly(httpOnly:Bool):ExternCookie;
    public function setMaxAge(maxAge:Integer):ExternCookie;
    public function setPath(path:String):ExternCookie;
    public function setSameSite(sameSite:Bool):ExternCookie;
    public function setSameSiteMode(mode:String):ExternCookie;
    public function setSecure(secure:Bool):ExternCookie;
    public function setValue(value:String):ExternCookie;
    public function setVerison(version:Integer):ExternCookie;
}


@:native("io.undertow.io.Sender")
extern interface SenderExtern {
    public function send(data:String):Void;
    public function close():Void;
}
@:native("io.undertow.server.BlockingHttpExchange")
extern interface BlockingHttpExchangeExtern {
    public function getInputStream():java.io.InputStream;
    public function getOutputStream():java.io.OutputStream;
    @:throws("java.io.IOException") public function close():Void;
}

@:native("io.undertow.util.HttpString")
extern class HttpStringExtern {
    public function new(key:String);
    @:to public function toString():String;
}

@:native("io.undertow.UndertowOptions")
extern class UndertowOptionsExtern {
    public static var MAX_HEADER_SIZE:Option<Int>;
    public static var MAX_ENTITY_SIZE:Option<Float>; // Long
    public static var MULTIPART_MAX_ENTITY_SIZE:Option<Float>; // Long
    public static var BUFFER_PIPELINED_DATA:Option<Bool>;
    public static var IDLE_TIMEOUT:Option<Int>;
    public static var REQUEST_PARSE_TIMEOUT:Option<Int>;
    public static var NO_REQUEST_TIMEOUT:Option<Int>;
    public static var MAX_PARAMETERS:Option<Int>;
    public static var MAX_HEADERS:Option<Int>;
    public static var MAX_COOKIES:Option<Int>;
    public static var DECODE_SLASH:Option<Bool>;
    public static var DECODE_URL:Option<Bool>;
    public static var URL_CHARSET:Option<String>;
    public static var ALWAYS_SET_KEEP_ALIVE:Option<Bool>;
    public static var ALWAYS_SET_DATE:Option<Bool>;
    public static var MAX_BUFFERED_REQUEST_SIZE:Option<Int>;
    public static var RECORD_REQUEST_START_TIME:Option<Bool>;
    public static var ALLOW_EQUALS_IN_COOKIE_VALUE:Option<Bool>;
    public static var DISABLE_RFC6265_COOKIE_PARSING:Option<Bool>;
    public static var ENABLE_RFC6265_COOKIE_VALIDATION:Option<Bool>;
    public static var ENABLE_HTTP2:Option<Bool>;
    public static var ENABLE_STATISTICS:Option<Bool>;
    public static var ALLOW_UNKNOWN_PROTOCOLS:Option<Bool>;
    public static var HTTP2_SETTINGS_HEADER_TABLE_SIZE:Option<Int>;
    public static var HTTP2_SETTINGS_ENABLE_PUSH:Option<Bool>;
    public static var HTTP2_SETTINGS_MAX_CONCURRENT_STREAMS:Option<Int>;
    public static var HTTP2_SETTINGS_INITIAL_WINDOW_SIZE:Option<Int>;
    public static var HTTP2_SETTINGS_MAX_FRAME_SIZE:Option<Int>;
    public static var HTTP2_PADDING_SIZE:Option<Int>;
    public static var HTTP2_HUFFMAN_CACHE_SIZE:Option<Int>;
    public static var MAX_CONCURRENT_REQUESTS_PER_CONNECTION:Option<Int>;
    public static var MAX_QUEUED_READ_BUFFERS:Option<Int>;
    public static var MAX_AJP_PACKET_SIZE:Option<Int>;
    public static var REQUIRE_HOST_HTTP11:Option<Bool>;
    public static var MAX_CACHED_HEADER_SIZE:Option<Int>;
    public static var HTTP_HEADERS_CACHE_SIZE:Option<Int>;
    public static var SSL_USER_CIPHER_SUITES_ORDER:Option<Bool>;
    public static var SSL_SNI_HOSTNAME:Option<String>;
    public static var ALLOW_UNESCAPED_CHARACTERS_IN_URL:Option<Bool>;
    public static var SHUTDOWN_TIMEOUT:Option<Int>;
    public static var ENDPOINT_IDENTIFICATION_ALGORITHM:Option<String>;
    public static var QUEUED_FRAMES_HIGH_WATER_MARK:Option<Int>;
    public static var QUEUED_FRAMES_LOW_WATER_MARK:Option<Int>;
    public static var AJP_ALLOWED_REQUEST_ATTRIBUTES_PATTERN:Option<String>;
    public static var TRACK_ACTIVE_REQUESTS:Option<Bool>;
    public static var RST_FRAMES_TIME_WINDOW:Option<Int>;
    public static var MAX_RST_FRAMES_PER_WINDOW:Option<Int>;
    public static var MEMORY_STORAGE_THRESHOLD:Option<Float>; // Long
    public static var WEB_SOCKETS_READ_TIMEOUT:Option<Int>;
    public static var WEB_SOCKETS_WRITE_TIMEOUT:Option<Int>;
}

@:native("org.xnio.Option")
extern class Option<T> {}

private abstract Job(Runnable) from Runnable to Runnable {
    public inline function new(job:() -> Void) {
        this = cast job;
    }
}
#end