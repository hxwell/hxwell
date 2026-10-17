package haxe;

#if java
class ThreadLocal<T> {
    // The JVM owns the values, so terminating a virtual thread also releases them.
    private var local:java.lang.ThreadLocal<T> = new java.lang.ThreadLocal<T>();
    private var initialValue:Void->T;
    private var removeValue:T->Void;

    public function new(?initialValue:Void->T, ?removeValue:T->Void) {
        this.initialValue = initialValue;
        this.removeValue = removeValue;
    }

    public function remove():Void {
        var value = local.get();
        local.remove();
        if(value != null && removeValue != null)
            removeValue(value);
    }

    public function set(value:T):Void {
        if(value == null)
            remove();
        else
            local.set(value);
    }

    public function get():T {
        var value = local.get();
        if(value == null && initialValue != null) {
            value = initialValue();
            local.set(value);
        }
        return value;
    }
}
#elseif (target.threaded)
import sys.thread.Thread;
import hx.concurrent.collection.SynchronizedMap;

class ThreadLocal<T> {
    public var elements:SynchronizedMap<Thread, T> = SynchronizedMap.newObjectMap();
    private var initialValue:Void->T;
    private var removeValue:T->Void;

    public function new(?initialValue:Void->T, ?removeValue:T->Void) {
        this.initialValue = initialValue;
        this.removeValue = removeValue;
    }

    public function remove():Void {
        var thread = Thread.current();
        var element:T = elements.get(thread);
        elements.remove(thread);
        if(element != null) {

            if(removeValue != null)
                removeValue(element);
        }
    }

    public function set(value: T) {
        if(value == null)
            remove();
        else
            elements.set(Thread.current(), value);
    }

    public function get(): T {
        var currentThread:Thread = Thread.current();

        if(!elements.exists(currentThread) && initialValue != null)
            elements.set(currentThread, initialValue());

        return elements.get(currentThread);
    }
}
#else
class ThreadLocal<T> {
    public var element:T = null;
    private var initialValue:Void->T;
    private var removeValue:T->Void;

    public function new(?initialValue:Void->T, ?removeValue:T->Void) {
        this.initialValue = initialValue;
        this.removeValue = removeValue;
    }

    public function remove():Void {
        var previous = element;
        element = null;
        if(previous != null && removeValue != null)
            removeValue(previous);
    }

    public function set(value:T) {
        if(value == null)
            remove();
        else
            element = value;
    }

    public function get():T {
        if(element == null && initialValue != null)
            element = initialValue();

        return element;
    }
}
#end
