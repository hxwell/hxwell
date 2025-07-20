package hx.well.thread;

#if (!target.threaded)
class FakeMutex {
    public function new() {
    }

    public inline function acquire():Void {}

    public inline function release():Void {}
}
#end