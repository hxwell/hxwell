package hx.well.internal;

import haxe.io.Bytes;

class SecureToken {
    private static inline var ALPHABET = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    #if java
    private static var random = new java.security.SecureRandom();
    #end

    public static function generate(length:Int):String {
        if(length <= 0)
            throw new haxe.Exception("Token length must be positive");

        #if java
        var bytes = Bytes.alloc(length);
        random.nextBytes(bytes.getData());
        #else
        var bytes = haxe.crypto.random.SecureRandom.bytes(length);
        #end
        var token = new StringBuf();
        // A 64-character alphabet divides 256 evenly; no modulo bias.
        for(i in 0...length)
            token.add(ALPHABET.charAt(bytes.get(i) & 63));
        return token.toString();
    }
}
