package hx.well.facades;
import haxe.crypto.BCrypt;
import haxe.io.Bytes;
class Hash {
    public static #if php inline #end function make(password:String, rounds:Int = 12):String {
        #if php
        return untyped php.Syntax.code("password_hash({0}, PASSWORD_BCRYPT, ['cost' => {1}])", password, rounds);
        #else
        var salt = BCrypt.generateSalt(rounds, BCrypt.Revision2B);
        return BCrypt.encode(password, salt);
        #end

    }

    public static inline function check(plaintext:String, hash:String):Bool {
        #if php
        return untyped php.Syntax.code("password_verify({0}, {1})", plaintext, hash);
        #else
        return BCrypt.verify(plaintext, hash);
        #end
    }
}