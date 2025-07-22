package hx.well.http.driver.undertow;

#if java
@:access(hx.well.http.Response)
class UndertowDriver extends AbstractHttpDriver<UndertowDriverConfig> {
    public var undertow:UndertowExtern;

    public function new(config:UndertowDriverConfig) {
        super(config);
    }

    public function start():Void {
        var undertowBuilder = UndertowExtern.builder()
        .addHttpListener(config.port, config.host)
        .setHandler(new UndertowHxwellHandler(this));

        for(keyValueIterator in config.serverOption.keyValueIterator()) {
            undertowBuilder.setServerOption(keyValueIterator.key, keyValueIterator.value);
        }

        for(keyValueIterator in config.socketOption.keyValueIterator()) {
            undertowBuilder.setSocketOption(keyValueIterator.key, keyValueIterator.value);
        }

        for(keyValueIterator in config.workerOption.keyValueIterator()) {
            undertowBuilder.setWorkerOption(keyValueIterator.key, keyValueIterator.value);
        }

        undertow = undertowBuilder.build();
        undertow.start();

        // Driver is started, invoke the onStart callback.
        config.onStart();
    }

    public function stop():Void {
        undertow.stop();
    }
}
#end