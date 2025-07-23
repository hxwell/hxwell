package hx.well.database.query;
import haxe.Exception;

class DeleteQueryBuilder {
    /**
     * Generates an SQL DELETE statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @return A formatted SQL DELETE string.
     */
    public static function toString<T>(query:QueryBuilder<T>):String {
        if (query.joins.length > 0) throw new Exception("Delete statements do not support JOINs.");
        if (query.conditions.length == 0 && !query.queryUnsafe) throw new Exception("Delete statements must have at least one condition or be marked as unsafe.");

        var sql = 'DELETE FROM ${query.model.getTable()}';
        if (query.conditions.length > 0) sql += ' WHERE ' + query.conditions.join(" AND ");
        if (query.limitValue > 0) sql += ' LIMIT ${query.limitValue}';
        return sql;
    }
}