package javax.crypto;

extern class KeyGenerator {
    public static function getInstance(algorithm:String):KeyGenerator;
    public function init(keysize:Int):Void;
    public function generateKey():SecretKey;
}
