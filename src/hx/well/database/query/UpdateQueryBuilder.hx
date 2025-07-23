package hx.well.database.query;

import haxe.Exception;
import hx.well.database.query.QueryBuilder.QueryCondition;

class UpdateQueryBuilder {
    /**
     * Generates an SQL UPDATE statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @param keys An iterator for the column names to update.
     * @return A formatted SQL UPDATE string.
     */
    public static function toString<T>(query:QueryBuilder<T>, keys:Iterator<String>):String {
        if (query.joins.length > 0) throw new Exception("UpdateQuery does not support joins.");
        if (query.conditions.length == 0 && !query.queryUnsafe) throw new Exception("Update statements must have at least one condition or be marked as unsafe.");

        var setClauses = [for (key in keys) '$key = ?'];
        var stringBuf = new StringBuf();
        stringBuf.add("UPDATE ");
        stringBuf.add(query.model.getTable());
        stringBuf.add(" SET ");
        stringBuf.add(setClauses.join(", "));
        
        if (query.conditions.length > 0) addWhereClause(query.conditions, stringBuf);
        if (query.limitValue > 0) {
            stringBuf.add(" LIMIT ");
            stringBuf.add(query.limitValue);
        }
        return stringBuf.toString();
    }

    private static function addWhereClause(conditions:Array<QueryCondition>, stringBuf:StringBuf):Void {
        stringBuf.add(" WHERE ");

        stringBuf.add(conditions[0].condition);
        for (i in 1...conditions.length) {
            stringBuf.add(" ");
            stringBuf.add(conditions[i].type);
            stringBuf.add(" ");
            stringBuf.add(conditions[i].condition);
        }
    }
}