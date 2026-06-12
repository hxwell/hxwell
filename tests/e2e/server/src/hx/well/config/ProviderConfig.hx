package hx.well.config;

import hx.well.provider.AbstractProvider;
import hx.well.provider.BootProvider;

class ProviderConfig implements IConfig {
    public function new() {}

    public function get():Array<Class<AbstractProvider>> {
        return [
            BootProvider
        ];
    }
}
