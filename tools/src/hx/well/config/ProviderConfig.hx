package hx.well.config;
import hx.well.provider.CLIProvider;
import hx.well.provider.AbstractProvider;
class ProviderConfig {
    public static function get():Array<Class<AbstractProvider>> {
        return [
            CLIProvider
        ];
    }
}