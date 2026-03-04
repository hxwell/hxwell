package hx.well.http.driver.undertow;

#if java
import java.nio.ByteBuffer;
import java.lang.Runnable;

/**
 * Extern declarations for Undertow's WebSocket API.
 *
 * Covers the handshake handler, connection callback, channel,
 * receive listener, and send utilities needed for WebSocket support.
 */
@:native("io.undertow.websockets.WebSocketConnectionCallback")
extern interface WebSocketConnectionCallbackExtern {
    public function onConnect(exchange:WebSocketHttpExchangeExtern, channel:WebSocketChannelExtern):Void;
}

@:native("io.undertow.websockets.WebSocketProtocolHandshakeHandler")
extern class WebSocketProtocolHandshakeHandlerExtern implements UndertowExtern.HttpHandlerExtern {
    public function new(callback:WebSocketConnectionCallbackExtern, next:UndertowExtern.HttpHandlerExtern):Void;

    public function handleRequest(exchange:UndertowExtern.HttpServerExchangeExtern):Void;
}

@:native("io.undertow.websockets.spi.WebSocketHttpExchange")
extern interface WebSocketHttpExchangeExtern {
    public function getRequestURI():String;

    public function getQueryString():String;
}

@:native("io.undertow.websockets.core.WebSocketChannel")
extern class WebSocketChannelExtern {
    public function getSourceAddress():java.net.InetSocketAddress;

    public function getReceiveSetter():ChannelListenerSetter<WebSocketChannelExtern>;

    public function resumeReceives():Void;

    public function close():Void;

    public function isOpen():Bool;
}

@:native("io.undertow.websockets.core.AbstractReceiveListener")
extern class AbstractReceiveListenerExtern implements ChannelListener<WebSocketChannelExtern> {
    public function new():Void;

    public function handleEvent(channel:WebSocketChannelExtern):Void;

    public function onFullTextMessage(channel:WebSocketChannelExtern, message:BufferedTextMessageExtern):Void;

    public function onFullBinaryMessage(channel:WebSocketChannelExtern, message:BufferedBinaryMessageExtern):Void;

    public function onCloseMessage(message:CloseMessageExtern, channel:WebSocketChannelExtern):Void;

    public function onError(channel:WebSocketChannelExtern, error:java.lang.Throwable):Void;
}

@:native("io.undertow.websockets.core.WebSockets")
extern class WebSocketsExtern {
    @:overload public static function sendText(message:String, channel:WebSocketChannelExtern, callback:WebSocketCallbackExtern):Void;

    @:overload public static function sendText(message:String, channel:WebSocketChannelExtern):Void;

    @:overload public static function sendBinary(data:ByteBuffer, channel:WebSocketChannelExtern, callback:WebSocketCallbackExtern):Void;

    @:overload public static function sendBinary(data:ByteBuffer, channel:WebSocketChannelExtern):Void;
}

@:native("io.undertow.websockets.core.WebSocketCallback")
extern interface WebSocketCallbackExtern {
}

@:native("io.undertow.websockets.core.BufferedTextMessage")
extern class BufferedTextMessageExtern {
    public function getData():String;
}

@:native("io.undertow.websockets.core.BufferedBinaryMessage")
extern class BufferedBinaryMessageExtern {
    public function getData():PooledByteBufferArrayExtern;
}

@:native("io.undertow.connector.PooledByteBufferArray")
extern interface PooledByteBufferArrayExtern {
    public function getResource():java.NativeArray<ByteBuffer>;
}

@:native("io.undertow.websockets.core.CloseMessage")
extern class CloseMessageExtern {
    public function getCode():Int;

    public function getReason():String;
}

@:native("org.xnio.ChannelListener$Setter")
extern interface ChannelListenerSetter<T> {
    public function set(listener:ChannelListener<T>):Void;
}

@:native("org.xnio.ChannelListener")
extern interface ChannelListener<T> {
    public function handleEvent(channel:T):Void;
}
#end
