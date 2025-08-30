package at.favre.lib.crypto.bcrypt;
import java.NativeArray;
import java.StdTypes.Int8;
extern class BCrypt {
    public static function withDefaults():Hasher;
    public static function verifyer():Verifyer;
}

@:native("at.favre.lib.crypto.bcrypt.BCrypt$Hasher")
extern class Hasher {
    public function hash(cost:Int, password:NativeArray<Int8>):NativeArray<Int8>;
}

@:native("at.favre.lib.crypto.bcrypt.BCrypt$Verifyer")
extern class Verifyer {
    public function verify(password:NativeArray<Int8>, bcryptHash:NativeArray<Int8>):Result;
}

@:native("at.favre.lib.crypto.bcrypt.BCrypt$Result")
extern class Result {
    public var verified:Bool;
}