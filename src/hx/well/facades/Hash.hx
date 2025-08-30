package hx.well.facades;
import haxe.crypto.BCrypt;
import haxe.io.Bytes;
class Hash {
    public static #if php inline #end function make(password:String, rounds:Int = 12):String {
        #if php
        return untyped php.Syntax.code("password_hash({0}, PASSWORD_BCRYPT, ['cost' => {1}])", password, rounds);
        #elseif java
        return Bytes.ofData(cast at.favre.lib.crypto.bcrypt.BCrypt.withDefaults().hash(rounds, cast Bytes.ofString(password).getData())).toString();
        #else
        var salt = BCrypt.generateSalt(rounds, BCrypt.Revision2B);
        return BCrypt.encode(password, salt);
        #end

    }

    public static inline function check(plaintext:String, hash:String):Bool {
        #if php
        return untyped php.Syntax.code("password_verify({0}, {1})", plaintext, hash);
        #elseif java
        return at.favre.lib.crypto.bcrypt.BCrypt.verifyer().verify(cast Bytes.ofString(plaintext).getData(), cast Bytes.ofString(hash).getData()).verified;
        #else
        return BCrypt.verify(plaintext, hash);
        #end
    }
}