package jvm.thread;

#if java
import java.lang.Runnable;
import java.lang.Thread;

class VirtualThread {
    public static function create(job : Void -> Void):Thread {
        return new VirtualHaxeThread(job).thread;
    }
}

@:native("java.lang.Thread")
extern class VirtualThreadExtern {
    // Constructor
    @:overload public function new(runnable:Runnable);
    // Instance methods
    @:overload public function start():Void;
    @:overload public function join():Void;

    // Static methods for virtual threads (Java 19+)
    @:overload public static function startVirtualThread(runnable:Runnable):Thread;
    @:overload public static function ofVirtual(runnable:Runnable):Thread;
    @:overload public static function ofVirtual():OfVirtual;
    @:overload public static function currentThread():VirtualThreadExtern;
    @:overload public function isVirtual():Bool;
}

@:native("java.lang.Thread$Builder$OfVirtual")
extern interface OfVirtual {
    public function unstarted(task:Runnable):java.lang.Thread;
}

private class VirtualHaxeThread {

    var job : Void -> Void;
    public var thread:Thread;

    public function new(job : Void -> Void) {
        this.job = job;
        thread = VirtualThreadExtern.ofVirtual().unstarted(run);
    }

    public function run() {
        job();
    }

}
#end
