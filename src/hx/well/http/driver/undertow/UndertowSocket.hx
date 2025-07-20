package hx.well.http.driver.undertow;
import sys.net.Socket;
import hx.well.http.driver.undertow.UndertowExtern.HttpServerExchangeExtern;
import hx.well.http.driver.undertow.UndertowExtern.BlockingHttpExchangeExtern;

#if haxe5
import jvm.io.NativeInput;
import jvm.io.NativeOutput;
#else
import java.io.NativeInput;
import java.io.NativeOutput;
#end

class UndertowSocket extends Socket {
    private var blockingExchange:BlockingHttpExchangeExtern;
    private var exchange:HttpServerExchangeExtern;

    public function new(exchange:HttpServerExchangeExtern) {
        super();
        this.exchange = exchange;

        this.blockingExchange = exchange.startBlocking();

        this.output = new NativeOutput(exchange.getOutputStream());
        this.input = new NativeInput(exchange.getInputStream());
    }

    public override function close():Void {
        blockingExchange.close();
    }
}