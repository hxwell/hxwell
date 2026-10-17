import haxe.Json;
import hx.well.database.schema.Blueprint;
import hx.well.database.schema.SchemaGrammar;
import hx.well.database.schema.MysqlSchemaGrammar;
import hx.well.database.schema.SqliteSchemaGrammar;

/** The same declarations are executed against Illuminate in reference.php. */
class SchemaCompatibility {
    static function definitions():Array<{name:String, define:Blueprint->Void}> {
        return [
            {name: "users", define: table -> {
                table.id();
                table.string("name");
                table.string("email").unique();
                table.integer("age").nullable().defaultValue(18);
                table.boolean("active").defaultValue(true);
                table.timestamps();
                table.softDeletes();
                table.rememberToken();
            }},
            {name: "scalar_types", define: table -> {
                table.increments("id");
                table.tinyInteger("tiny");
                table.smallInteger("small").unsigned();
                table.mediumInteger("medium");
                table.bigInteger("big");
                table.char("code", 4);
                table.text("body");
                table.mediumText("medium_body");
                table.longText("long_body");
                table.float("ratio");
                table.double("distance");
                table.decimal("price", 12, 3);
                table.binary("payload");
                table.json("metadata");
                table.uuid();
                table.ulid();
                table.ipAddress();
                table.macAddress();
            }},
            {name: "date_types", define: table -> {
                table.date("day");
                table.dateTime("moment");
                table.dateTimeTz("moment_tz");
                table.time("clock");
                table.timeTz("clock_tz");
                table.timestamp("created").useCurrent();
                table.timestampTz("updated").useCurrentOnUpdate().nullable();
                table.year("year");
                table.datetimes();
            }},
            {name: "choices", define: table -> {
                table.id();
                table.enumeration("state", ["Open", "Closed"]).defaultValue("Open");
                table.string("label").defaultValue("O'Reilly");
            }},
            {name: "memberships", define: table -> {
                table.unsignedBigInteger("user_id");
                table.unsignedBigInteger("team_id");
                table.primary(["user_id", "team_id"]);
                table.index(["team_id", "user_id"]);
            }},
            {name: "attachments", define: table -> {
                table.id();
                table.morphs("owner");
                table.nullableUuidMorphs("subject");
                table.nullableUlidMorphs("actor");
            }},
            {name: "UsersCase", define: table -> {
                table.id();
                table.string("Email").unique();
                table.index(["Email"], "ExactIndex");
            }},
            {name: "generated", define: table -> {
                table.integer("value");
                table.integer("doubled").storedAs("value * 2").nullable();
                table.integer("tripled").virtualAs("value * 3").nullable();
            }},
            {name: "posts", define: table -> {
                table.id();
                table.foreignId("user_id").nullable().constrained().cascadeOnDelete();
                table.foreignUuid("owner_uuid").nullable().constrained("owners", "uuid").nullOnDelete();
            }}
        ];
    }

    static function compile(grammar:SchemaGrammar):Dynamic {
        var result:Dynamic = {};
        for (scenario in definitions()) {
            var blueprint = new Blueprint(scenario.name);
            scenario.define(blueprint);
            Reflect.setField(result, scenario.name, grammar.compileCreate(blueprint));
        }
        var alter = new Blueprint("users");
        alter.string("nickname", 100).nullable();
        alter.renameColumn("name", "display_name");
        alter.dropUnique(["email"]);
        Reflect.setField(result, "alter_users", grammar.compileAlter(alter));
        return result;
    }

    #if php
    static function sqliteWorkflow():Dynamic {
        hx.well.database.Connection.create("compat", {path: ":memory:"});
        var schema = hx.well.facades.Schema.connection("compat");
        var db = new hx.well.facades.DB().setConnection("compat");
        schema.enableForeignKeyConstraints();
        schema.create("users", table -> {
            table.id();
            table.string("name");
            table.string("email").unique();
            table.integer("age").nullable();
        });
        db.insert("INSERT INTO users (name, email) VALUES (?, ?)", "Ayse", "ayse@example.com");
        schema.create("posts", table -> {
            table.id();
            table.foreignId("user_id").nullable().constrained().cascadeOnDelete();
            table.integer("score");
            table.integer("doubled").storedAs("score * 2").nullable();
        });
        db.insert("INSERT INTO posts (user_id, score) VALUES (?, ?)", 1, 5);
        db.insert("INSERT INTO posts (user_id, score) VALUES (?, ?)", null, 6);
        var invalidForeign = rejects(() -> db.insert("INSERT INTO posts (user_id, score) VALUES (?, ?)", 999, 1));
        schema.table("users", table -> table.text("name").nullable().change());
        schema.table("users", table -> table.renameIndex("users_email_unique", "email_unique"));
        var uniqueEnforced = rejects(() -> db.insert("INSERT INTO users (email) VALUES (?)", "ayse@example.com"));
        db.insert("INSERT INTO users (name, email) VALUES (?, ?)", null, "second@example.com");
        schema.table("users", table -> table.renameColumn("age", "years"));
        schema.dropColumns("users", ["years"]);
        var result = {
            generatedColumns: schema.getColumnListing("posts"),
            usersColumns: schema.getColumnListing("users"),
            hasIndex: schema.hasIndex("users", "email_unique"),
            invalidForeign: invalidForeign,
            uniqueEnforced: uniqueEnforced,
            names: [for (row in db.select("SELECT name FROM users ORDER BY id")) row.name],
            generated: [for (row in db.select("SELECT doubled FROM posts ORDER BY id")) Std.parseInt(Std.string(row.doubled))],
            survivingPosts: 0
        };
        db.delete("DELETE FROM users WHERE id = ?", 1);
        result.survivingPosts = db.select("SELECT * FROM posts").length;
        hx.well.database.Connection.free();
        return result;
    }

    static function rejects(callback:()->Void):Bool {
        try { callback(); } catch (_:Dynamic) { return true; }
        return false;
    }
    #end

    static function main() {
        var result:Dynamic = {mysql: compile(new MysqlSchemaGrammar()), sqlite: compile(new SqliteSchemaGrammar())};
        #if php
        Reflect.setField(result, "workflow", sqliteWorkflow());
        #end
        Sys.println(Json.stringify(result));
    }
}
