package hx.well.io;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.io.Input;
import hx.well.zip.Compress;
import haxe.zip.FlushMode;
import StringTools;
import haxe.Exception;
import hx.well.http.encoding.DeflateEncodingOptions;

/**
 * LAZY PROCESSING VERSION - Loads and processes chunks on demand
 */
class ChunkedDeflateCompressInput extends Input {
    private var input:Input;
    private var compress:Compress;

    private var readyChunks:Array<Bytes> = [];
    private var currentChunkBuffer:BytesInput = null;
    private var sourceFinished:Bool = false;
    private var compressionFinished:Bool = false;
    private var bufsize:Int = 0;

    private var chunkSize:Int;

    private static final EMPTY_BYTES = Bytes.alloc(0);
    private static final END_BYTES = Bytes.ofString("0\r\n\r\n");
    private static final TRAILER_BYTES = Bytes.ofString("\r\n");

    public function new(input:Input, deflateEncondingOptions:DeflateEncodingOptions) {
        this.input = input;
        compress = new Compress(deflateEncondingOptions.level);
        compress.setFlushMode(FlushMode.SYNC);

        chunkSize = deflateEncondingOptions.chunkSize;
        //trace('ChunkedCompressInput: Initialized with compression level $level');
    }

    private function createFormattedChunk(chunkData:Bytes):Bytes {
        var header = StringTools.hex(chunkData.length) + "\r\n";
        var result = new BytesBuffer();
        result.addString(header);
        result.add(chunkData);
        result.add(TRAILER_BYTES);
        return result.getBytes();
    }

    private function processInputChunk():Void {
        if (sourceFinished) return;

        var chunkBytes:Bytes = Bytes.alloc(chunkSize);
        var actualSize:Int = 0;

        try {
            actualSize = input.readBytes(chunkBytes, 0, chunkSize);
            if (actualSize != chunkSize) {
                chunkBytes = chunkBytes.sub(0, actualSize);
                sourceFinished = true;
                //trace('processInputChunk: Read final chunk of ${actualSize} bytes');
            } else {
                //trace('processInputChunk: Read chunk of ${actualSize} bytes');
            }
        } catch (e:Exception) {
            //trace('processInputChunk: EOF caught while reading input - ${e.message}');
            sourceFinished = true;
            actualSize = 0;
        }

        if (actualSize > 0) {
            compressChunk(chunkBytes);
        }

        if (sourceFinished && !compressionFinished) {
            finishCompression();
        }
    }

    private function compressChunk(inputBytes:Bytes):Void {
        try {
            var outputBuffer = Bytes.alloc(bufsize);
            var srcPos = 0;
            var totalCompressed = new BytesBuffer();

            while (srcPos < inputBytes.length) {
                var result = compress.execute(inputBytes, srcPos, outputBuffer, 0);

                if (result.write > 0) {
                    totalCompressed.add(outputBuffer.sub(0, result.write));
                    //trace('compressChunk: Compressed ${result.read} -> ${result.write} bytes');
                }

                srcPos += result.read;

                if (result.read == 0 && result.write == 0) {
                    break;
                }
            }

            var compressedData = totalCompressed.getBytes();
            if (compressedData.length > 0) {
                var formattedChunk = createFormattedChunk(compressedData);
                readyChunks.push(formattedChunk);
                //trace('compressChunk: Added formatted chunk (${compressedData.length} -> ${formattedChunk.length} bytes)');
            }

        } catch (e:Exception) {
            //trace('compressChunk: Compression error - ${e.message}');
            //trace(CallStack.toString(e.stack));
        }
    }

    private function finishCompression():Void {
        if (compressionFinished) return;

        try {
            compress.setFlushMode(FlushMode.FINISH);

            var outputBuffer = Bytes.alloc(bufsize);
            var emptyInput = EMPTY_BYTES;
            var totalFinal = new BytesBuffer();

            var done = false;
            while (!done) {
                var result = compress.execute(emptyInput, 0, outputBuffer, 0);

                if (result.write > 0) {
                    totalFinal.add(outputBuffer.sub(0, result.write));
                    //trace('finishCompression: Final flush wrote ${result.write} bytes');
                }

                done = result.done;

                if (result.read == 0 && result.write == 0) {
                    break;
                }
            }

            var finalData = totalFinal.getBytes();
            if (finalData.length > 0) {
                var formattedChunk = createFormattedChunk(finalData);
                readyChunks.push(formattedChunk);
                //trace('finishCompression: Added final compressed chunk (${finalData.length} bytes)');
            }

        } catch (e:Exception) {
            //trace('finishCompression: Error during final compression - ${e.message}');
        }

        readyChunks.push(END_BYTES);
        compressionFinished = true;
        //trace('finishCompression: Added final end marker');
    }

    private function ensureDataAvailable():Void {
        if (readyChunks.length == 0 && !compressionFinished) {
            processInputChunk();
        }
    }

    private function ensureCurrentChunk():Void {
        if (currentChunkBuffer != null && currentChunkBuffer.position < currentChunkBuffer.length) {
            return;
        }

        if (readyChunks.length > 0) {
            currentChunkBuffer = new BytesInput(readyChunks.shift());
            //trace('ensureCurrentChunk: Loaded next chunk (${currentChunkBuffer.length} bytes)');
            return;
        }

        if (!compressionFinished) {
            ensureDataAvailable();
            if (readyChunks.length > 0) {
                currentChunkBuffer = new BytesInput(readyChunks.shift());
                //trace('ensureCurrentChunk: Loaded new chunk (${currentChunkBuffer.length} bytes)');
            }
        }
    }

    override public function readByte():Int {
        ensureCurrentChunk();
        if (currentChunkBuffer != null && currentChunkBuffer.position < currentChunkBuffer.length) {
            return currentChunkBuffer.readByte();
        }
        //trace('readByte: EOF - no more data');
        throw new Eof();
    }

    override public function readBytes(s:Bytes, pos:Int, len:Int):Int {
        if (pos < 0 || len < 0 || pos + len > s.length) {
            throw Error.OutsideBounds;
        }

        if(bufsize == 0)
        {
            bufsize = len - pos;
            trace('Buffer size set to $bufsize');
        }

        var bytesRead = 0;
        while (bytesRead < len) {
            ensureCurrentChunk();
            
            if (currentChunkBuffer == null || currentChunkBuffer.position >= currentChunkBuffer.length) {
                if (compressionFinished && readyChunks.length == 0) {
                    // Eğer hiç data okumadıysak EOF throw et, yoksa okunan data'yı return et
                    if (bytesRead == 0) {
                        throw new Eof();
                    } else {
                        break;
                    }
                }
                continue;
            }

            var remainingInChunk = currentChunkBuffer.length - currentChunkBuffer.position;
            var toRead = Std.int(Math.min(len - bytesRead, remainingInChunk));
            var readSize = currentChunkBuffer.readBytes(s, pos + bytesRead, toRead);
            if(readSize == 0)
                break;
            bytesRead += toRead;
        }
        return bytesRead;
    }

    override public function close():Void {
        readyChunks = [];
        currentChunkBuffer = null;
        input.close();
        compress.close();

        super.close();
        //trace('close: Resources cleaned up');
    }
}