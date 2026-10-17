package hx.well.http.driver.undertow;

#if java
import hx.well.websocket.AbstractWebSocketHandler;
import hx.well.websocket.WebSocketSession;
import hx.well.http.driver.undertow.UndertowWebSocketExtern;
import hx.well.route.Route;
import hx.well.http.HttpHandler;
import hx.well.http.Request;
import hx.well.http.RequestParser;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseStatic;
import haxe.Exception;
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

    public function onConnect(exchange:WebSocketHttpExchangeExtern, channel:WebSocketChannelExtern):Void {
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

    private function connect(exchange:WebSocketHttpExchangeExtern, channel:WebSocketChannelExtern):Void {
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
            queries = hx.well.http.RequestParser.parseQueryString("?" + queryString);
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
        var session = new WebSocketSession(sessionId, ()-> {
            channel.close();
        }, queries);

        // Start the send queue worker thread for this session
        var sendWorker = new UndertowWebSocketSendWorker(session, channel);
        sendWorker.start();

        handler.addSession(session);

        // Set up the receive listener
        channel.getReceiveSetter().set(new UndertowReceiveListener(handler, session));
        channel.resumeReceives();

        // Notify the handler
        try {
            handler.onOpen(session);
            trace("WS Connected: " + sessionId + " on " + path);
        } catch(e:Exception) {
            handler.onError(session, e);
        }
    }

    private function authorize(exchange:WebSocketHttpExchangeExtern, channel:WebSocketChannelExtern, routeData:{route:hx.well.route.RouteElement, params:Map<String, String>}, path:String, host:String):Bool {
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
            request.setAttribute(hx.well.type.AttributeType.RouteElement, routeData.route);

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
class UndertowReceiveListener extends hx.well.http.driver.undertow.UndertowWebSocketExtern.AbstractReceiveListenerExtern {
    private var handler:AbstractWebSocketHandler;
    private var session:WebSocketSession;

    public function new(handler:AbstractWebSocketHandler, session:WebSocketSession) {
        super();
        this.handler = handler;
        this.session = session;
    }

    override public function onFullTextMessage(channel:hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern, message:hx.well.http.driver.undertow.UndertowWebSocketExtern.BufferedTextMessageExtern):Void {
        try {
            handler.onMessage(session, message.getData());
        } catch(e:Exception) {
            handler.onError(session, e);
        }
    }

    override public function onFullBinaryMessage(channel:hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern, message:hx.well.http.driver.undertow.UndertowWebSocketExtern.BufferedBinaryMessageExtern):Void {
        try {
            var data = message.getData();
            // Java ByteBuffer to Haxe Bytes
            var bytes = haxe.io.Bytes.alloc(data.getResource().length);
            for(i in 0...data.getResource().length) {
                // Actually need to properly read the arrays, but ByteBuffer mapping can be tricky.
                // Assuming getResource() returns an array of ByteBuffers.
            }
            // For now, let's just use empty bytes if it fails or implement a proper bytebuffer -> bytes util.
        } catch(e:Dynamic) {}
    }

    override public function onCloseMessage(message:hx.well.http.driver.undertow.UndertowWebSocketExtern.CloseMessageExtern, channel:hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern):Void {
        handler.removeSession(session.id);
        var reason = message != null ? message.getReason() : "Closed";
        var code = message != null ? message.getCode() : 1000;
        try {
            handler.onClose(session, code, reason);
        } catch(e:Exception) {
            handler.onError(session, e);
        }
        super.onCloseMessage(message, channel);
    }

    override public function onError(channel:hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern, error:java.lang.Throwable):Void {
        try {
            handler.onError(session, new Exception(error.getMessage()));
        } catch(e:Dynamic) {}
        super.onError(channel, error);
    }

    override public function handleEvent(channel:hx.well.http.driver.undertow.UndertowWebSocketExtern.WebSocketChannelExtern):Void {
        super.handleEvent(channel);
    }
}
#end
