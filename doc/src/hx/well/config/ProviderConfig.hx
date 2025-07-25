package hx.well.config;
import hx.well.provider.AbstractProvider;
import hx.well.provider.CLIProvider;
class ProviderConfig {
    public static function get():Array<Class<AbstractProvider>> {
        return [];
    }
}