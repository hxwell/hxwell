package hx.well.config;
import hx.well.provider.CLIProvider;
import hx.well.provider.AbstractProvider;
class ProviderConfig implements IConfig {
    public function new() {}

    public function get():Array<Class<AbstractProvider>> {
        return [
            CLIProvider
        ];
    }
}