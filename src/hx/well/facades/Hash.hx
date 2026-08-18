package hx.well.facades;
import haxe.crypto.BCrypt;
import haxe.io.Bytes;
class Hash {
    #if (target.threaded && !php)
    private static var lock:hx.concurrent.lock.RLock = new hx.concurrent.lock.RLock();
    #end

    public static #if php inline #end function make(password:String, rounds:Int = 12):String {
        #if php
        return untyped php.Syntax.code("password_hash({0}, PASSWORD_BCRYPT, ['cost' => {1}])", password, rounds);
        #else
        return withLock(() -> {
            var salt = BCrypt.generateSalt(rounds, BCrypt.Revision2B);
            return BCrypt.encode(password, salt);
        });
        #end

    }

    public static #if php inline #end function check(plaintext:String, hash:String):Bool {
        #if php
        return untyped php.Syntax.code("password_verify({0}, {1})", plaintext, hash);
        #else
        return withLock(() -> BCrypt.verify(plaintext, hash));
        #end
    }

    #if !php
    private static function withLock<T>(callback:Void->T):T {
        #if target.threaded
        lock.acquire();
        try {
            var result = callback();
            lock.release();
            return result;
        } catch (e:Dynamic) {
            lock.release();
            throw e;
        }
        #else
        return callback();
        #end
    }
    #end
}
