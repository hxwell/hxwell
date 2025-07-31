package hx.well.http.driver.socket;

#if (!php && !js)
import hx.concurrent.executor.Executor;

class SocketDriverConfig extends AbstractDriverConfig {
    /**
     * Creates the `Executor` to be used by the driver.
     *
     * This method can be overridden in a subclass to allow for customizations,
     * such as using a different thread pool size or providing a completely
     * different `Executor` implementation.
     */
    public function executor():Executor {
        return Executor.create(poolSize);
    }
}
#end