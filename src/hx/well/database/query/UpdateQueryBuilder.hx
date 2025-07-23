package hx.well.database.query;

import haxe.Exception;

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
        var sql = 'UPDATE ${query.model.getTable()} SET ${setClauses.join(", ")}';
        if (query.conditions.length > 0) sql += ' WHERE ' + query.conditions.join(" AND ");
        if (query.limitValue > 0) sql += ' LIMIT ${query.limitValue}';
        return sql;
    }
}