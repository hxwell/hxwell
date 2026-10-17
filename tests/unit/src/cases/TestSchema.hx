package cases;

#if (neko || hl || cpp || php)
import utest.Assert;
import sys.FileSystem;
import hx.well.database.Connection;
import hx.well.facades.DB;
import hx.well.facades.Schema;

class TestSchema extends utest.Test {
    static var prepared:Bool = false;

    function setup() {
        if (!prepared) {
            if (FileSystem.exists("unit-test.db"))
                FileSystem.deleteFile("unit-test.db");
            Connection.create("default", {path: "unit-test.db"});
            prepared = true;
        }

        Schema.dropIfExists("schema_posts");
        Schema.dropIfExists("schema_users");
    }

    function teardown() {
        Connection.free();
    }

    function createUsers() {
        Schema.create("schema_users", table -> {
            table.id();
            table.string("name");
            table.string("email").unique();
            table.integer("age").nullable();
            table.timestamps();
        });
    }

    function testCreateAndHasTable() {
        Assert.isFalse(Schema.hasTable("schema_users"));

        createUsers();

        Assert.isTrue(Schema.hasTable("schema_users"));
        Assert.isTrue(Schema.hasColumn("schema_users", "email"));
        Assert.isFalse(Schema.hasColumn("schema_users", "yok"));

        var columns = Schema.getColumnListing("schema_users");
        Assert.contains("id", columns);
        Assert.contains("name", columns);
        Assert.contains("created_at", columns);
    }

    function testInsertRoundtrip() {
        createUsers();

        var db = new DB();
        var firstId = db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "ayse", "ayse@example.com");
        Assert.equals(1, firstId);

        var rows = db.select("SELECT * FROM `schema_users` WHERE `email` = ?", "ayse@example.com");
        Assert.equals(1, rows.length);
        Assert.equals("ayse", rows[0].name);
    }

    function testUniqueIndexEnforced() {
        createUsers();

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "ayse", "ayse@example.com");
        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "kopya", "ayse@example.com"));
    }

    function testAlterAddColumn() {
        createUsers();

        Schema.table("schema_users", table -> {
            table.string("nickname", 100).nullable();
        });

        Assert.isTrue(Schema.hasColumn("schema_users", "nickname"));
    }

    function testForeignKeyCreate() {
        createUsers();

        Schema.create("schema_posts", table -> {
            table.id();
            table.foreignId("user_id");
            table.text("body");
            table.foreign("user_id").references("id").on("schema_users").cascadeOnDelete();
        });

        Assert.isTrue(Schema.hasTable("schema_posts"));
        Assert.isTrue(Schema.hasColumn("schema_posts", "user_id"));
    }

    function testDrop() {
        createUsers();
        Assert.isTrue(Schema.hasTable("schema_users"));

        Schema.drop("schema_users");
        Assert.isFalse(Schema.hasTable("schema_users"));

        Schema.dropIfExists("schema_users");
        Assert.pass();
    }

    function testChangeColumnPreservesData() {
        createUsers();

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`name`, `email`, `age`) VALUES (?, ?, ?)", "ayse", "ayse@example.com", 30);
        db.insert("INSERT INTO `schema_users` (`name`, `email`, `age`) VALUES (?, ?, ?)", "baris", "baris@example.com", 31);

        Schema.table("schema_users", table -> {
            table.text("name").nullable().change();
        });

        var rows = db.select("SELECT * FROM `schema_users` ORDER BY `id`");
        Assert.equals(2, rows.length);
        Assert.equals("ayse", rows[0].name);
        Assert.equals("baris", rows[1].name);
        Assert.equals(1, Std.parseInt(Std.string(rows[0].id)));

        db.insert("INSERT INTO `schema_users` (`email`) VALUES (?)", "bos@example.com");
        Assert.equals(3, db.select("SELECT * FROM `schema_users`").length);

        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "kopya", "ayse@example.com"));

        var nextId = db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "yeni", "yeni@example.com");
        Assert.equals(4, nextId);
    }

    function testRenameIndex() {
        createUsers();

        Assert.isTrue(Schema.hasIndex("schema_users", "schema_users_email_unique"));

        Schema.table("schema_users", table -> {
            table.renameIndex("schema_users_email_unique", "email_unique_idx");
        });

        Assert.isFalse(Schema.hasIndex("schema_users", "schema_users_email_unique"));
        Assert.isTrue(Schema.hasIndex("schema_users", "email_unique_idx"));

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "ayse", "ayse@example.com");
        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "kopya", "ayse@example.com"));
    }

    function testHasColumnsAndDropColumns() {
        createUsers();

        Assert.isTrue(Schema.hasColumns("schema_users", ["name", "email"]));
        Assert.isFalse(Schema.hasColumns("schema_users", ["name", "yok"]));

        Schema.dropColumns("schema_users", ["age"]);
        Assert.isFalse(Schema.hasColumn("schema_users", "age"));
    }

    function testTableListing() {
        createUsers();

        Assert.contains("schema_users", Schema.getTableListing());
    }

    function testWhenTableHasColumn() {
        createUsers();

        Schema.whenTableHasColumn("schema_users", "age", table -> {
            table.string("age_note").nullable();
        });
        Assert.isTrue(Schema.hasColumn("schema_users", "age_note"));

        Schema.whenTableDoesntHaveColumn("schema_users", "age", table -> {
            table.string("olmamali").nullable();
        });
        Assert.isFalse(Schema.hasColumn("schema_users", "olmamali"));
    }

    function testWithoutForeignKeyConstraints() {
        createUsers();

        var executed = false;
        Schema.withoutForeignKeyConstraints(() -> {
            executed = true;
        });
        Assert.isTrue(executed);
    }

    function testConstrainedForeignKey() {
        createUsers();

        Schema.create("schema_posts", table -> {
            table.id();
            table.foreignId("user_id").constrained("schema_users");
            table.text("body");
        });

        Assert.isTrue(Schema.hasTable("schema_posts"));
        Assert.isTrue(Schema.hasColumn("schema_posts", "user_id"));
    }

    function testChangeColumnKeepsCheckConstraint() {
        Schema.create("schema_users", table -> {
            table.id();
            table.enumeration("status", ["active", "banned"]);
            table.string("name");
        });

        Schema.table("schema_users", table -> {
            table.text("name").nullable().change();
        });

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`status`, `name`) VALUES (?, ?)", "active", "ayse");
        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`status`, `name`) VALUES (?, ?)", "bogus", "x"));
    }

    function testChangeColumnKeepsGeneratedColumn() {
        Schema.create("schema_users", table -> {
            table.id();
            table.integer("a");
            table.integer("b");
            table.integer("total").storedAs("a + b");
        });

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`a`, `b`) VALUES (?, ?)", 2, 3);

        Schema.table("schema_users", table -> {
            table.integer("a").nullable().change();
        });

        var rows = db.select("SELECT `total` FROM `schema_users`");
        Assert.equals(1, rows.length);
        Assert.equals(5, Std.parseInt(Std.string(rows[0].total)));
    }

    function testFailedChangeRollsBack() {
        createUsers();

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "ayse", "ayse@example.com");

        Assert.raises(() -> Schema.table("schema_users", table -> {
            table.integer("age").change();
        }));

        Assert.isFalse(Schema.getTableListing().contains("__tmp_schema_users"));
        Assert.isTrue(Schema.hasTable("schema_users"));
        Assert.equals(1, db.select("SELECT * FROM `schema_users`").length);

        Schema.table("schema_users", table -> {
            table.integer("age").nullable().defaultValue(0).change();
        });
        Assert.equals(1, db.select("SELECT * FROM `schema_users`").length);
    }

    function testChangeColumnWithUnique() {
        Schema.create("schema_users", table -> {
            table.id();
            table.string("code");
        });

        Schema.table("schema_users", table -> {
            table.string("code", 50).unique().change();
        });

        Assert.isTrue(Schema.hasIndex("schema_users", "schema_users_code_unique"));

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`code`) VALUES (?)", "a");
        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`code`) VALUES (?)", "a"));
    }

    function testChangePrimaryKeyColumn() {
        createUsers();

        var db = new DB();
        db.insert("INSERT INTO `schema_users` (`name`, `email`) VALUES (?, ?)", "ayse", "ayse@example.com");

        Schema.table("schema_users", table -> {
            table.integer("id").change();
        });

        var primary = [for (row in db.select("PRAGMA table_info(`schema_users`)")) if (Std.parseInt(Std.string(row.pk)) > 0) Std.string(row.name)];
        Assert.same(["id"], primary);
        Assert.raises(() -> db.insert("INSERT INTO `schema_users` (`id`, `name`, `email`) VALUES (?, ?, ?)", 1, "kopya", "kopya@example.com"));
    }

    function testGeneratedColumnsAreListed() {
        Schema.create("schema_users", table -> {
            table.integer("value");
            table.integer("doubled").storedAs("value * 2");
            table.integer("tripled").virtualAs("value * 3");
        });
        Assert.same(["value", "doubled", "tripled"], Schema.getColumnListing("schema_users"));
        Assert.isTrue(Schema.hasColumn("schema_users", "DOUBLED"));
        Assert.isTrue(Schema.hasColumns("schema_users", ["doubled", "tripled"]));
    }

    function testRenameIndexPreservesExpressionsAndPredicate() {
        createUsers();
        var db = new DB();
        Connection.get().request("CREATE UNIQUE INDEX active_name ON schema_users (lower(name) COLLATE NOCASE DESC) WHERE age > 18");
        Schema.table("schema_users", table -> table.renameIndex("active_name", "adult_name"));
        var sql = Std.string(db.select("SELECT sql FROM sqlite_master WHERE name = 'adult_name'")[0].sql);
        Assert.isTrue(sql.indexOf("lower(name) COLLATE NOCASE DESC") != -1);
        Assert.isTrue(sql.indexOf("WHERE age > 18") != -1);
        Assert.isFalse(Schema.hasIndex("schema_users", "active_name"));
        db.insert("INSERT INTO schema_users (name, email, age) VALUES (?, ?, ?)", "Ayse", "first@example.com", 20);
        Assert.raises(() -> db.insert("INSERT INTO schema_users (name, email, age) VALUES (?, ?, ?)", "ayse", "second@example.com", 21));
        db.insert("INSERT INTO schema_users (name, email, age) VALUES (?, ?, ?)", "ayse", "child@example.com", 12);
        Assert.equals(2, db.select("SELECT * FROM schema_users").length);

        Assert.raises(() -> Schema.table("schema_users", table -> table.renameIndex("adult_name", "schema_users_email_unique")));
        Assert.isTrue(Schema.hasIndex("schema_users", "adult_name"));
    }

    function testNullableConstrainedForeignKeyEnforced() {
        createUsers();
        Schema.create("schema_posts", table -> {
            table.id();
            table.foreignId("user_id").nullable().constrained("schema_users").cascadeOnDelete();
        });
        var db = new DB();
        Schema.enableForeignKeyConstraints();
        var id = db.insert("INSERT INTO schema_users (name, email) VALUES (?, ?)", "Ayse", "ayse@example.com");
        db.insert("INSERT INTO schema_posts (user_id) VALUES (?)", id);
        db.insert("INSERT INTO schema_posts (user_id) VALUES (?)", null);
        Assert.raises(() -> db.insert("INSERT INTO schema_posts (user_id) VALUES (?)", 999));
        db.delete("DELETE FROM schema_users WHERE id = ?", id);
        Assert.equals(1, db.select("SELECT * FROM schema_posts").length);
        Schema.disableForeignKeyConstraints();
    }

    function testChangePreservesAutoincrementAfterDeletingAllRows() {
        createUsers();
        var db = new DB();
        db.insert("INSERT INTO schema_users (id, name, email) VALUES (?, ?, ?)", 100, "Ayse", "ayse@example.com");
        db.delete("DELETE FROM schema_users");
        Schema.table("schema_users", table -> table.text("name").nullable().change());
        Assert.equals(101, db.insert("INSERT INTO schema_users (email) VALUES (?)", "next@example.com"));
    }

    function testChangeInsideTransactionDoesNotCascadeDeleteChildren() {
        createUsers();
        Schema.create("schema_posts", table -> {
            table.foreignId("user_id").constrained("schema_users").cascadeOnDelete();
        });
        var db = new DB();
        Schema.enableForeignKeyConstraints();
        db.insert("INSERT INTO schema_users (name, email) VALUES (?, ?)", "Ayse", "ayse@example.com");
        db.insert("INSERT INTO schema_posts (user_id) VALUES (?)", 1);
        Assert.raises(() -> db.transaction(() -> Schema.table("schema_users", table -> table.text("name").change())));
        Assert.equals(1, db.select("SELECT * FROM schema_users").length);
        Assert.equals(1, db.select("SELECT * FROM schema_posts").length);
        Assert.equals(1, Std.parseInt(Std.string(db.select("PRAGMA foreign_keys")[0].foreign_keys)));
        Assert.isFalse(Schema.hasTable("__tmp_schema_users"));
        Schema.disableForeignKeyConstraints();
    }

    function testChangeColumnWithLeadingComment() {
        var db = new DB();
        Connection.get().request("CREATE TABLE schema_users (/* name */ name VARCHAR NOT NULL, value INTEGER)");
        db.insert("INSERT INTO schema_users (name, value) VALUES (?, ?)", "Ayse", 7);
        Schema.table("schema_users", table -> table.text("name").nullable().change());
        db.insert("INSERT INTO schema_users (name, value) VALUES (?, ?)", null, 8);
        Assert.equals(2, db.select("SELECT * FROM schema_users").length);
    }

    function testChangeColumnKeepsForeignKeyName() {
        createUsers();

        Schema.create("schema_posts", table -> {
            table.id();
            table.foreignId("user_id").constrained("schema_users").cascadeOnDelete();
            table.string("title");
        });

        Schema.table("schema_posts", table -> {
            table.text("title").change();
        });

        var db = new DB();
        var sql = Std.string(db.select("SELECT `sql` FROM `sqlite_master` WHERE `name` = ?", "schema_posts")[0].sql);
        Assert.isTrue(sql.indexOf("CONSTRAINT `schema_posts_user_id_foreign`") != -1);
        Assert.isTrue(sql.indexOf("ON DELETE CASCADE") != -1);
    }
}
#end
