package hx.well.facades;
import hx.concurrent.executor.Executor;
import hx.concurrent.executor.Schedule.ScheduleWeekday;
import hx.concurrent.executor.Schedule as ConcurrentSchedule;
import haxe.Exception;
import hx.well.database.Connection;
import haxe.ds.Either;
import hx.well.console.CommandExecutor;
import haxe.extern.EitherType;
class Schedule {
    private static var __schedule:Schedule = new Schedule();

    public static function get():Schedule {
        return __schedule;
    }

    private static var executor:Executor = Executor.create(1);

    public function new() {

    }

    public function once<T>(command:EitherType<TaskFuture<T>->T, String>, ?initialDelayMS:Int):TaskFuture<T> {
        return submit(command, ONCE(initialDelayMS));
    }

    public function fixedRate<T>(command:EitherType<TaskFuture<T>->T, String>, intervalMS:Int, ?initialDelayMS:Int):TaskFuture<T> {
        return submit(command, FIXED_RATE(intervalMS, initialDelayMS));
    }

    public function fixedDelay<T>(command:EitherType<TaskFuture<T>->T, String>, intervalMS:Int, ?initialDelayMS:Int):TaskFuture<T> {
        return submit(command, FIXED_DELAY(intervalMS, initialDelayMS));
    }

    public function hourly<T>(command:EitherType<TaskFuture<T>->T, String>, ?minute:Int, ?second:Int):TaskFuture<T> {
        return submit(command, HOURLY(minute, second));
    }

    public function daily<T>(command:EitherType<TaskFuture<T>->T, String>, ?hour:Int, ?minute:Int, ?second:Int):TaskFuture<T> {
        return submit(command, DAILY(hour, minute, second));
    }

    public function weekly<T>(command:EitherType<TaskFuture<T>->T, String>, ?day:ScheduleWeekday, ?hour:Int, ?minute:Int, ?second:Int):TaskFuture<T> {
        return submit(command, WEEKLY(day, hour, minute, second));
    }

    public function submit<T>(command:EitherType<TaskFuture<T>->T, String>, schedule:ConcurrentSchedule):TaskFuture<T> {
        var future:TaskFuture<T>;

        return future = executor.submit(() -> {
            var value:Null<T> = null;

            try {
                if(command is String) {
                    var valueString:String = cast command;
                    value = CommandExecutor.executeRaw(valueString, future);
                }else{
                    var valueFunction:TaskFuture<T>->T = cast command;
                    value = valueFunction(future);
                }
            } catch (e:Exception) {
                // Free database connections
                Connection.free();

                throw e;
            }

            // Free database connections
            Connection.free();

            return value;
        }, schedule);
    }
}
