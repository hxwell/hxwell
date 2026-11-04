package hx.well.storage;

import haxe.io.Input;

/** Adapter methods receive normalized, disk-relative paths and throw on I/O errors.
    Streams returned by readStream belong to the caller; writeStream must not close
    the caller's input. Adapters must enforce their own root and link policy. */
interface IStorageAdapter {
    public function fileExists(path:String):Bool;
    public function directoryExists(path:String):Bool;
    public function readStream(path:String):Input;
    public function writeStream(path:String, input:Input, ?visibility:String):Void;
    public function delete(path:String):Void;
    public function copy(from:String, to:String):Void;
    public function move(from:String, to:String):Void;
    public function size(path:String):Int;
    public function lastModified(path:String):Float;
    public function mimeType(path:String):String;
    public function getVisibility(path:String):String;
    public function setVisibility(path:String, visibility:String):Void;
    public function files(directory:String, recursive:Bool):Array<String>;
    public function directories(directory:String, recursive:Bool):Array<String>;
    public function makeDirectory(path:String):Void;
    public function deleteDirectory(path:String):Void;
    public function path(path:String):String;
}
