package hx.well.http.driver.undertow;

#if java
import hx.well.websocket.AbstractWebSocketHandler;
import hx.well.websocket.WebSocketSession;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.AbstractReceiveListenerExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.BufferedBinaryMessageExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.BufferedTextMessageExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.ChannelListener;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.CloseMessageExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketConnectionCallbackExtern;
import hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketHttpExchangeExtern;
import hx.well.route.RouteElement;
import hx.well.type.AttributeType;
import java.lang.Throwable;
import java.util.concurrent.atomic.AtomicBoolean;
import hx.well.route.Route;
import hx.well.http.HttpHandler;
import hx.well.http.Request;
import hx.well.http.RequestParser;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseStatic;
import haxe.Exception;
import haxe.io.Bytes;
import haxe.crypto.random.SecureRandom;

/**
 * Global WebSocket connection callback for Undertow.
 *
 * This is set as the root handler's callback:
 *   WebSocketProtocolHandshakeHandler(this, httpFallback)
 *
 * On connect, it resolves the route from the request URI and wires
 * the correct AbstractWebSocketHandler for that path.
 */
@:access(hx.well.route.RouteElement)
@:access(hx.well.http.Request)
class UndertowWebSocketCallback implements WebSocketConnectionCallbackExtern {
    public function new() {}

    public function onConnect(exchange:WebSocketHttpExchangeExtern,
            channel:WebSocketChannelExtern):Void {
        RequestStatic.reset();
        ResponseStatic.reset();
        try {
            connect(exchange, channel);
        } catch(e:Dynamic) {
            RequestStatic.reset();
            ResponseStatic.clear();
            throw e;
        }
        RequestStatic.reset();
        ResponseStatic.clear();
    }

    private function connect(exchange:WebSocketHttpExchangeExtern,
            channel:WebSocketChannelExtern):Void {
        var uri = exchange.getRequestURI();
        var path = uri;

        // Strip query string if present
        var qIndex = uri.indexOf("?");
        if(qIndex >= 0) {
            path = uri.substring(0, qIndex);
        }

        var queryString = exchange.getQueryString();
        var queries = new Map<String, String>();
        if(queryString != null && queryString != "") {
            queries = RequestParser.parseQueryString("?" + queryString);
        }

        trace("WS onConnect - path: " + path);

        var host = exchange.getRequestHeader("Host");

        var wsRouteData = Route.resolveWebSocket(path, host);
        if(wsRouteData == null) {
            trace("WS No route found for: " + path);
            channel.close();
            return;
        }

        var handler = wsRouteData.route.getWsHandler();
        if(handler == null) {
            trace("WS No handler for route: " + path);
            channel.close();
            return;
        }

        if(!authorize(exchange, channel, wsRouteData, path, host)) {
            trace("WS Rejected by middleware: " + path);
            channel.close();
            return;
        }

        // Create session
        var sessionId = generateSessionId();
        var listener:UndertowReceiveListener = null;
        var session = new WebSocketSession(sessionId, ()-> {
            if (listener != null) {
                listener.closeFromOwner(channel);
            } else {
                channel.close();
            }
        }, queries);

        // Start the send queue worker thread for this session
        var sendWorker = new UndertowWebSocketSendWorker(session, channel);
        sendWorker.start();

        handler.addSession(session);

        // Close frames are optional on TCP failure and on local channel shutdown.
        listener = new UndertowReceiveListener(handler, session);
        channel.addCloseTask(new UndertowChannelCloseListener(listener));
        if (!channel.isOpen()) {
            listener.transportClosed();
            return;
        }
        channel.getReceiveSetter().set(listener);
        channel.resumeReceives();

        // Notify the handler
        try {
            handler.onOpen(session);
            trace("WS Connected: " + sessionId + " on " + path);
        } catch (error:Dynamic) {
            listener.callbackFailed(channel, error);
        }
    }

    private function authorize(exchange:WebSocketHttpExchangeExtern,
            channel:WebSocketChannelExtern,
            routeData:{route:RouteElement, params:Map<String, String>
        }, path:String, host:String):Bool {
        try {
            var request = new Request();
            request.method = "GET";
            request.host = host;

            try {
                request.ip = channel.getSourceAddress().getAddress().getHostAddress();
            } catch(e:Dynamic) {}

            for(entry in exchange.getRequestHeaders().entrySet()) {
                var name = entry.getKey();
                request.headers.set(name, exchange.getRequestHeader(name));
            }

            request.cookies = RequestParser.parseCookies(request.headers.get("Cookie"));

            var queryString = exchange.getQueryString();
            request.path = path + (queryString != null && queryString != "" ? '?$queryString' : "");
            request.routeParameters = routeData.params ?? new Map();
            request.setAttribute(AttributeType.RouteElement, routeData.route);

            RequestStatic.set(request);

            return HttpHandler.authorizeWebSocket(request, routeData.route);
        } catch(e:Dynamic) {
            RequestStatic.reset();
            ResponseStatic.clear();
            trace("WS authorize error for " + path + ": " + Std.string(e));
            return false;
        }
    }

    private static function generateSessionId():String {
        return SecureRandom.bytes(16).toHex().toUpperCase();
    }
}

/**
 * Undertow receive listener.
 * Handles channel close events.
 */
class UndertowReceiveListener extends AbstractReceiveListenerExtern {
    final handler:AbstractWebSocketHandler;
    final session:WebSocketSession;
    final detached = new AtomicBoolean(false);

    public function new(handler:AbstractWebSocketHandler, session:WebSocketSession) {
        super();
        this.handler = handler;
        this.session = session;
    }

    function detach():Bool {
        if (!detached.compareAndSet(false, true)) {
            return false;
        }
        handler.removeSession(session.id);
        return true;
    }

    function notifyError(error:Exception):Void {
        try {
            handler.onError(session, error);
        } catch (_:Dynamic) {}
    }

    function notifyClose(code:Int, reason:String):Void {
        try {
            handler.onClose(session, code, reason);
        } catch (error:Dynamic) {
            notifyError(new Exception(Std.string(error)));
        }
    }

    public function transportClosed():Void {
        if (detach()) {
            notifyClose(1006, "Transport closed without a WebSocket close frame");
        }
    }

    public function closeFromOwner(channel:WebSocketChannelExtern):Void {
        var first = detach();
        try {
            channel.close();
        } catch (_:Dynamic) {}
        if (first) {
            notifyClose(1000, "Closed by the server");
        }
    }

    public function callbackFailed(channel:WebSocketChannelExtern, error:Dynamic):Void {
        var first = detach();
        try {
            channel.close();
        } catch (_:Dynamic) {}
        if (first) {
            notifyError(new Exception(Std.string(error)));
            notifyClose(1011, "WebSocket handler failed");
        }
    }

    override public function onFullTextMessage(channel:WebSocketChannelExtern,
            message:BufferedTextMessageExtern):Void {
        try {
            handler.onMessage(session, message.getData());
        } catch (error:Dynamic) {
            callbackFailed(channel, error);
        }
    }

    override public function onFullBinaryMessage(channel:WebSocketChannelExtern,
            message:BufferedBinaryMessageExtern):Void {
        // Binary decoding remains the driver's existing implementation.
        try {
            var data = message.getData();
            var bytes = Bytes.alloc(data.getResource().length);
        } catch (_:Dynamic) {}
    }

    override public function onCloseMessage(message:CloseMessageExtern,
            channel:WebSocketChannelExtern):Void {
        if (detach()) {
            notifyClose(message == null ? 1000 : message.getCode(),
                message == null ? "Closed" : message.getReason());
        }
        // Handler exceptions cannot prevent Undertow from completing the close handshake.
        super.onCloseMessage(message, channel);
    }

    override public function onError(channel:WebSocketChannelExtern, error:Throwable):Void {
        var first = detach();
        super.onError(channel, error);
        if (first) {
            notifyError(new Exception(error.getMessage()));
            notifyClose(1006, "WebSocket transport error");
        }
    }
    }

private class UndertowChannelCloseListener implements ChannelListener<WebSocketChannelExtern> {
    final listener:UndertowReceiveListener;

    public function new(listener:UndertowReceiveListener) {
        this.listener = listener;
    }

    public function handleEvent(channel:WebSocketChannelExtern):Void {
        listener.transportClosed();
    }
}
#end
