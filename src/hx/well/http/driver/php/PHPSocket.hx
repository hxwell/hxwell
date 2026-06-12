package hx.well.http.driver.php;

#if php
import sys.net.Socket;

class PHPSocket extends Socket {
    public static function make() {
        return Type.createEmptyInstance(Socket);
    }
}
#end
