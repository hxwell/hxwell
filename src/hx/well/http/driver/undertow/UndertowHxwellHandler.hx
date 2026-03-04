package hx.well.http.driver.undertow;

#if java
import hx.well.http.driver.undertow.UndertowExtern.HttpHandlerExtern;
import hx.well.http.driver.undertow.UndertowExtern.HttpServerExchangeExtern;
import haxe.Exception;
import haxe.CallStack;

@:access(hx.well.exception.AbortException)
@:access(hx.well.http.Request)
class UndertowHxwellHandler implements HttpHandlerExtern {
    private var driver:UndertowDriver;

    public function new(driver:UndertowDriver) {
        this.driver = driver;
    }

    public function handleRequest(exchange:HttpServerExchangeExtern):Void {
        var upgradeHeaderStr = "Upgrade";
        var upgradeHeader = exchange.getRequestHeaders().get(new hx.well.http.driver.undertow.UndertowExtern.HttpStringExtern("Upgrade"));
        var upgradeVal = upgradeHeader != null ? upgradeHeader.getFirst() : "null";

        trace("HTTP Handler reached - path: " + exchange.getRequestPath() + " method: " + exchange.getRequestMethod().toString() + " upgrade: " + upgradeVal);

        exchange.startBlocking();
        exchange.dispatch(cast (() -> {
            var context:UndertowDriverContext = null;
            try {
                context = new UndertowDriverContext(exchange);
                HttpHandler.process(context);
            } catch (e:Exception) {
                // TODO: Log the exception
                trace(e, CallStack.toString(e.stack));

                tryClose(context);
            }
        }));
    }

    private function tryClose(context:UndertowDriverContext):Void {
        try {
            context?.close();
        } catch (e:Exception) {

        }
    }
}
#end
