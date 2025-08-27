package hx.well.database.query;
import haxe.Exception;

class InsertQueryBuilder {
    /**
     * Generates an SQL INSERT statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @param keys An iterator for the column names to insert data into.
     * @return A formatted SQL INSERT string.
     */
    public static function toString<T>(query:QueryBuilder<T>, iterKeys:Iterator<String>):String {
        if (query.conditions.length > 0) throw new Exception("INSERT statements do not support WHERE clauses.");
        if (query.joins.length > 0) throw new Exception("INSERT statements do not support JOINs.");
        if (query.orderByClause != "") throw new Exception("INSERT statements do not support ORDER BY.");
        if (query.limitValue != -1) throw new Exception("INSERT statements do not support LIMIT.");
        if (!iterKeys.hasNext()) throw new Exception("Cannot perform an INSERT with no columns specified.");

        var keys:Array<String> = [for (key in iterKeys) key];
        var columns = keys.join(", ");
        var placeholders = [for (_ in 0...keys.length) "?"].join(", ");

        var stringBuf = new StringBuf();
        stringBuf.add("INSERT INTO ");
        stringBuf.add(query.model.getTable());
        stringBuf.add(" (");
        stringBuf.add(columns);
        stringBuf.add(") VALUES (");
        stringBuf.add(placeholders);
        stringBuf.add(")");

        return stringBuf.toString();
    }
}