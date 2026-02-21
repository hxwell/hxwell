package hx.well.facades;
import sys.db.Connection;
import hx.well.database.Connection as HxWellConnection;
import sys.db.ResultSet;
using hx.well.tools.StringTools;

class DB {
    private var connectionKey:String = "default";

    public function new() {

    }

    public function setConnection(connectionKey:String):DB {
        this.connectionKey = connectionKey;
        return this;
    }

    private var connection(get, never):Connection;

    private function get_connection():Connection {
        #if debug
        trace(connectionKey);
        #end
        return HxWellConnection.get(connectionKey);
    }

    public function select(rawQuery:String, ...parameters:Dynamic):Array<Dynamic> {
        return [for(value in query(rawQuery, ...parameters).results()) value];
    }

    public function update(rawQuery:String, ...parameters:Dynamic):Int {
        var resultSet:ResultSet = query(rawQuery, ...parameters);
        return resultSet.length;
    }

    public function delete(rawQuery:String, ...parameters:Dynamic):Int {
        var resultSet:ResultSet = query(rawQuery, ...parameters);
        return resultSet.length;
    }

    public function insert(rawQuery:String, ...parameters:Dynamic):Int {
        query(rawQuery, ...parameters);
        return connection.lastInsertId();
    }

    public function query(rawQuery:String, ...parameters:Dynamic):ResultSet {
        var parameterCount:Int = 0;
        var insideString = false;
        var currentQuote:Null<String> = null;

        for (i in 0...rawQuery.length) {
            var char = rawQuery.charAt(i);
            if (insideString) {
                if (char == currentQuote) {
                    insideString = false;
                    currentQuote = null;
                }
            } else if (char == "'" || char == "\"") {
                insideString = true;
                currentQuote = char;
            } else if (char == "?") {
                parameterCount++;
            }
        }

        if (parameterCount != parameters.length)
            throw '${parameterCount} parameters requested but ${parameters.length} found';

        // Insert parameters without quotation marks
        var parts = [];
        var currentPart = "";
        insideString = false;
        currentQuote = null;
        var paramIndex = 0;

        for (i in 0...rawQuery.length) {
            var char = rawQuery.charAt(i);
            if (insideString) {
                currentPart += char;
                if (char == currentQuote) {
                    insideString = false;
                    currentQuote = null;
                }
            } else if (char == "'" || char == "\"") {
                insideString = true;
                currentQuote = char;
                currentPart += char;
            } else if (char == "?") {
                parts.push(currentPart);
                parts.push(quote(parameters[paramIndex]));
                paramIndex++;
                currentPart = "";
            } else {
                currentPart += char;
            }
        }
        parts.push(currentPart);
        var query = parts.join("");

        return connection.request(query);
    }

    public function quote(value:Dynamic):String
    {
        var stringBuf:StringBuf = new StringBuf();
        connection.addValue(stringBuf, value);
        return stringBuf.toString();
    }

    public function transaction(callback:()->Void):Void {
        connection.startTransaction();
        try {
            callback();
            connection.commit();
        } catch (e) {
            connection.rollback();
            throw e;
        }
    }
}