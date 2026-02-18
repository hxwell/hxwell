package java.security;
import haxe.io.BytesData;

extern class SecureRandom {
    public function new():Void;
    public function nextBytes(bytesData:BytesData):Void;
    public function nextInt():Int;
}