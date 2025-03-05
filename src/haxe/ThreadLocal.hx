package haxe;

#if (target.threaded)
import haxe.ds.WeakMap;
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
        var element:T = elements.get(Thread.current());
        if(element != null) {

            if(removeValue != null)
                removeValue(element);

            elements.remove(Thread.current());
        }
    }

    public function set(value: T) {
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
        if(element != null) {

            if(removeValue != null)
                removeValue(element);

            element = null;
        }
    }

    public function set(value:T) {
        element = value;
    }

    public function get():T {
        if(element == null && initialValue != null)
            element = initialValue();

        return element;
    }
}
#end