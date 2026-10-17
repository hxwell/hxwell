package cases;

import utest.Assert;
import haxe.Exception;
import hx.well.database.schema.Blueprint;
import hx.well.database.schema.MysqlSchemaGrammar;
import hx.well.database.schema.SqliteSchemaGrammar;
import hx.well.database.schema.SqliteTableDefinition;

class TestSchemaGrammar extends utest.Test {
    var mysql:MysqlSchemaGrammar;
    var sqlite:SqliteSchemaGrammar;

    function setup() {
        mysql = new MysqlSchemaGrammar();
        sqlite = new SqliteSchemaGrammar();
    }

    function usersBlueprint():Blueprint {
        var blueprint = new Blueprint("users");
        blueprint.id();
        blueprint.string("name");
        blueprint.string("email").unique();
        blueprint.integer("age").nullable().defaultValue(18);
        blueprint.boolean("active").defaultValue(true);
        blueprint.timestamps();
        return blueprint;
    }

    function testCreateMysql() {
        var statements = mysql.compileCreate(usersBlueprint());
        Assert.equals(2, statements.length);
        Assert.equals(
            "CREATE TABLE `users` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, "
            + "`name` VARCHAR(255) NOT NULL, `email` VARCHAR(255) NOT NULL, "
            + "`age` INT NULL DEFAULT 18, `active` TINYINT(1) NOT NULL DEFAULT 1, "
            + "`created_at` TIMESTAMP NULL, `updated_at` TIMESTAMP NULL)",
            statements[0]);
        Assert.equals("ALTER TABLE `users` ADD UNIQUE `users_email_unique` (`email`)", statements[1]);
    }

    function testCreateSqlite() {
        var statements = sqlite.compileCreate(usersBlueprint());
        Assert.equals(2, statements.length);
        Assert.equals(
            "CREATE TABLE `users` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
            + "`name` VARCHAR NOT NULL, `email` VARCHAR NOT NULL, "
            + "`age` INTEGER DEFAULT 18, `active` TINYINT(1) NOT NULL DEFAULT 1, "
            + "`created_at` DATETIME, `updated_at` DATETIME)",
            statements[0]);
        Assert.equals("CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`)", statements[1]);
    }

    function testForeignKey() {
        var blueprint = new Blueprint("posts");
        blueprint.id();
        blueprint.foreignId("user_id");
        blueprint.foreign("user_id").references("id").on("users").cascadeOnDelete();

        var statements = mysql.compileCreate(blueprint);
        Assert.equals(
            "CREATE TABLE `posts` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, "
            + "`user_id` BIGINT UNSIGNED NOT NULL, "
            + "CONSTRAINT `posts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE)",
            statements[0]);

        var sqliteStatements = sqlite.compileCreate(blueprint);
        Assert.equals(
            "CREATE TABLE `posts` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
            + "`user_id` INTEGER NOT NULL, "
            + "CONSTRAINT `posts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE)",
            sqliteStatements[0]);
    }

    function testForeignKeyWithoutOnRaises() {
        var blueprint = new Blueprint("posts");
        blueprint.foreignId("user_id");
        blueprint.foreign("user_id").references("id");

        Assert.raises(() -> mysql.compileCreate(blueprint), Exception);
    }

    function testCompositePrimaryAndIndex() {
        var blueprint = new Blueprint("role_user");
        blueprint.unsignedBigInteger("role_id");
        blueprint.unsignedBigInteger("user_id");
        blueprint.primary(["role_id", "user_id"]);
        blueprint.index(["user_id", "role_id"]);

        var statements = mysql.compileCreate(blueprint);
        Assert.equals(
            "CREATE TABLE `role_user` (`role_id` BIGINT UNSIGNED NOT NULL, "
            + "`user_id` BIGINT UNSIGNED NOT NULL, PRIMARY KEY (`role_id`, `user_id`))",
            statements[0]);
        Assert.equals("ALTER TABLE `role_user` ADD INDEX `role_user_user_id_role_id_index` (`user_id`, `role_id`)", statements[1]);

        var sqliteStatements = sqlite.compileCreate(blueprint);
        Assert.equals(
            "CREATE TABLE `role_user` (`role_id` INTEGER NOT NULL, "
            + "`user_id` INTEGER NOT NULL, PRIMARY KEY (`role_id`, `user_id`))",
            sqliteStatements[0]);
        Assert.equals("CREATE INDEX `role_user_user_id_role_id_index` ON `role_user` (`user_id`, `role_id`)", sqliteStatements[1]);
    }

    function testEnumColumn() {
        var blueprint = new Blueprint("orders");
        blueprint.enumeration("status", ["pending", "shipped"]);

        Assert.equals(
            "CREATE TABLE `orders` (`status` ENUM('pending', 'shipped') NOT NULL)",
            mysql.compileCreate(blueprint)[0]);
        Assert.equals(
            "CREATE TABLE `orders` (`status` VARCHAR CHECK (`status` IN ('pending', 'shipped')) NOT NULL)",
            sqlite.compileCreate(blueprint)[0]);
    }

    function testDecimalAndUseCurrent() {
        var blueprint = new Blueprint("payments");
        blueprint.decimal("amount", 10, 4);
        blueprint.timestamp("paid_at").useCurrent();

        Assert.equals(
            "CREATE TABLE `payments` (`amount` DECIMAL(10, 4) NOT NULL, "
            + "`paid_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)",
            mysql.compileCreate(blueprint)[0]);
        Assert.equals(
            "CREATE TABLE `payments` (`amount` NUMERIC NOT NULL, "
            + "`paid_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)",
            sqlite.compileCreate(blueprint)[0]);
    }

    function testAlterTable() {
        var blueprint = new Blueprint("users");
        blueprint.string("nickname", 100).nullable();
        blueprint.dropColumn("age");
        blueprint.renameColumn("name", "full_name");
        blueprint.dropIndex("users_email_unique");

        var statements = mysql.compileAlter(blueprint);
        Assert.equals("ALTER TABLE `users` ADD COLUMN `nickname` VARCHAR(100) NULL", statements[0]);
        Assert.equals("ALTER TABLE `users` DROP COLUMN `age`", statements[1]);
        Assert.equals("ALTER TABLE `users` RENAME COLUMN `name` TO `full_name`", statements[2]);
        Assert.equals("ALTER TABLE `users` DROP INDEX `users_email_unique`", statements[3]);

        var sqliteStatements = sqlite.compileAlter(blueprint);
        Assert.equals("ALTER TABLE `users` ADD COLUMN `nickname` VARCHAR", sqliteStatements[0]);
        Assert.equals("ALTER TABLE `users` DROP COLUMN `age`", sqliteStatements[1]);
        Assert.equals("ALTER TABLE `users` RENAME COLUMN `name` TO `full_name`", sqliteStatements[2]);
        Assert.equals("DROP INDEX `users_email_unique`", sqliteStatements[3]);
    }

    function testSqliteRejectsUnsupportedAlters() {
        var primaryBlueprint = new Blueprint("users");
        primaryBlueprint.primary("id");
        Assert.raises(() -> sqlite.compileAlter(primaryBlueprint), Exception);

        var foreignBlueprint = new Blueprint("posts");
        foreignBlueprint.foreign("user_id").references("id").on("users");
        Assert.raises(() -> sqlite.compileAlter(foreignBlueprint), Exception);
    }

    function testDropAndRename() {
        Assert.equals("DROP TABLE `users`", mysql.compileDrop("users"));
        Assert.equals("DROP TABLE IF EXISTS `users`", sqlite.compileDropIfExists("users"));
        Assert.equals("RENAME TABLE `users` TO `members`", mysql.compileRename("users", "members"));
        Assert.equals("ALTER TABLE `users` RENAME TO `members`", sqlite.compileRename("users", "members"));
    }

    function testStringDefaultIsQuoted() {
        var blueprint = new Blueprint("settings");
        blueprint.string("locale").defaultValue("o'br");

        Assert.equals(
            "CREATE TABLE `settings` (`locale` VARCHAR(255) NOT NULL DEFAULT 'o''br')",
            mysql.compileCreate(blueprint)[0]);
    }

    function testExtendedIntegerTypes() {
        var blueprint = new Blueprint("counters");
        blueprint.tinyIncrements("id");
        blueprint.unsignedTinyInteger("a");
        blueprint.unsignedSmallInteger("b");
        blueprint.unsignedMediumInteger("c");

        Assert.equals(
            "CREATE TABLE `counters` (`id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, "
            + "`a` TINYINT UNSIGNED NOT NULL, `b` SMALLINT UNSIGNED NOT NULL, `c` MEDIUMINT UNSIGNED NOT NULL)",
            mysql.compileCreate(blueprint)[0]);
        Assert.equals(
            "CREATE TABLE `counters` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
            + "`a` INTEGER NOT NULL, `b` INTEGER NOT NULL, `c` INTEGER NOT NULL)",
            sqlite.compileCreate(blueprint)[0]);
    }

    function testMiscTypes() {
        var blueprint = new Blueprint("misc");
        blueprint.year("y");
        blueprint.ipAddress("ip");
        blueprint.macAddress("mac");
        blueprint.ulid("u");
        blueprint.jsonb("payload");
        blueprint.point("location", 4326);

        Assert.equals(
            "CREATE TABLE `misc` (`y` YEAR NOT NULL, `ip` VARCHAR(45) NOT NULL, "
            + "`mac` VARCHAR(17) NOT NULL, `u` CHAR(26) NOT NULL, `payload` JSON NOT NULL, "
            + "`location` POINT SRID 4326 NOT NULL)",
            mysql.compileCreate(blueprint)[0]);
        Assert.equals(
            "CREATE TABLE `misc` (`y` INTEGER NOT NULL, `ip` VARCHAR NOT NULL, "
            + "`mac` VARCHAR NOT NULL, `u` VARCHAR NOT NULL, `payload` TEXT NOT NULL, "
            + "`location` GEOMETRY NOT NULL)",
            sqlite.compileCreate(blueprint)[0]);
    }

    function testSetColumn() {
        var blueprint = new Blueprint("flags");
        blueprint.set("perms", ["read", "write"]);

        Assert.equals(
            "CREATE TABLE `flags` (`perms` SET('read', 'write') NOT NULL)",
            mysql.compileCreate(blueprint)[0]);
        Assert.raises(() -> sqlite.compileCreate(blueprint), Exception);
    }

    function testMorphs() {
        var blueprint = new Blueprint("tags");
        blueprint.morphs("taggable");

        var statements = mysql.compileCreate(blueprint);
        Assert.equals(
            "CREATE TABLE `tags` (`taggable_type` VARCHAR(255) NOT NULL, `taggable_id` BIGINT UNSIGNED NOT NULL)",
            statements[0]);
        Assert.equals(
            "ALTER TABLE `tags` ADD INDEX `tags_taggable_type_taggable_id_index` (`taggable_type`, `taggable_id`)",
            statements[1]);
    }

    function testColumnModifiersMysql() {
        var blueprint = new Blueprint("users");
        blueprint.string("name").charset("utf8mb4").collation("utf8mb4_unicode_ci").comment("kullanici adi").after("id");
        blueprint.integer("total").storedAs("a + b");
        blueprint.timestamp("updated_at").useCurrent().useCurrentOnUpdate();
        blueprint.integer("position").first();

        Assert.equals(
            "CREATE TABLE `users` ("
            + "`name` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'kullanici adi' AFTER `id`, "
            + "`total` INT AS (a + b) STORED NOT NULL, "
            + "`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
            + "`position` INT NOT NULL FIRST)",
            mysql.compileCreate(blueprint)[0]);
    }

    function testTableOptions() {
        var blueprint = new Blueprint("logs");
        blueprint.integer("n");
        blueprint.engine("InnoDB");
        blueprint.charset("utf8mb4");
        blueprint.collation("utf8mb4_unicode_ci");
        blueprint.comment("log tablosu");

        Assert.equals(
            "CREATE TABLE `logs` (`n` INT NOT NULL) ENGINE = InnoDB DEFAULT CHARACTER SET utf8mb4 "
            + "COLLATE utf8mb4_unicode_ci COMMENT = 'log tablosu'",
            mysql.compileCreate(blueprint)[0]);

        var temporaryBlueprint = new Blueprint("temp_stats");
        temporaryBlueprint.integer("n");
        temporaryBlueprint.temporary();
        Assert.equals("CREATE TEMPORARY TABLE `temp_stats` (`n` INTEGER NOT NULL)", sqlite.compileCreate(temporaryBlueprint)[0]);
    }

    function testFullTextAndSpatial() {
        var blueprint = new Blueprint("articles");
        blueprint.text("body").fullText();
        blueprint.fullText(["title", "body"]);
        blueprint.geometry("area").spatialIndex();

        var statements = mysql.compileCreate(blueprint);
        Assert.equals("ALTER TABLE `articles` ADD FULLTEXT `articles_body_fulltext` (`body`)", statements[1]);
        Assert.equals("ALTER TABLE `articles` ADD SPATIAL INDEX `articles_area_spatialindex` (`area`)", statements[2]);
        Assert.equals("ALTER TABLE `articles` ADD FULLTEXT `articles_title_body_fulltext` (`title`, `body`)", statements[3]);

        Assert.raises(() -> sqlite.compileCreate(blueprint), Exception);
    }

    function testChangeColumnMysql() {
        var blueprint = new Blueprint("users");
        blueprint.string("name", 100).nullable().change();

        Assert.equals(
            "ALTER TABLE `users` MODIFY `name` VARCHAR(100) NULL",
            mysql.compileAlter(blueprint)[0]);
        Assert.raises(() -> sqlite.compileAlter(blueprint), Exception);
    }

    function testRenameIndexGrammar() {
        var blueprint = new Blueprint("users");
        blueprint.renameIndex("old_idx", "new_idx");

        Assert.equals("ALTER TABLE `users` RENAME INDEX `old_idx` TO `new_idx`", mysql.compileAlter(blueprint)[0]);
        Assert.raises(() -> sqlite.compileAlter(blueprint), Exception);
    }

    function testConstrained() {
        var blueprint = new Blueprint("posts");
        blueprint.foreignId("user_id").constrained();

        Assert.equals(
            "CREATE TABLE `posts` (`user_id` BIGINT UNSIGNED NOT NULL, "
            + "CONSTRAINT `posts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`))",
            mysql.compileCreate(blueprint)[0]);

        var explicitBlueprint = new Blueprint("posts");
        explicitBlueprint.foreignUuid("owner_id").constrained("accounts", "uuid");
        Assert.equals(
            "CREATE TABLE `posts` (`owner_id` CHAR(36) NOT NULL, "
            + "CONSTRAINT `posts_owner_id_foreign` FOREIGN KEY (`owner_id`) REFERENCES `accounts` (`uuid`))",
            mysql.compileCreate(explicitBlueprint)[0]);
    }

    function testDropShortcuts() {
        var blueprint = new Blueprint("users");
        blueprint.dropTimestamps();
        blueprint.dropForeign(["user_id"]);
        blueprint.dropUnique(["email"]);

        var statements = mysql.compileAlter(blueprint);
        Assert.equals("ALTER TABLE `users` DROP COLUMN `created_at`", statements[0]);
        Assert.equals("ALTER TABLE `users` DROP COLUMN `updated_at`", statements[1]);
        Assert.equals("ALTER TABLE `users` DROP FOREIGN KEY `users_user_id_foreign`", statements[2]);
        Assert.equals("ALTER TABLE `users` DROP INDEX `users_email_unique`", statements[3]);
    }

    function testUniqueWithCustomNameModifier() {
        var blueprint = new Blueprint("users");
        blueprint.string("email").unique("ozel_unique");

        Assert.equals("ALTER TABLE `users` ADD UNIQUE `ozel_unique` (`email`)", mysql.compileCreate(blueprint)[1]);
    }

    function testInvalidIdentifierRaises() {
        var blueprint = new Blueprint("users");
        blueprint.string("name; DROP TABLE users");
        Assert.raises(() -> mysql.compileCreate(blueprint), Exception);

        Assert.raises(() -> mysql.compileCreate(new Blueprint("users`")), Exception);
    }

    function testChangeIncrementsMysql() {
        var blueprint = new Blueprint("users");
        blueprint.bigIncrements("id").change();
        Assert.equals("ALTER TABLE `users` MODIFY `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT", mysql.compileAlter(blueprint)[0]);

        var primaryBlueprint = new Blueprint("users");
        primaryBlueprint.bigIncrements("id").primary().change();
        Assert.equals("ALTER TABLE `users` MODIFY `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY", mysql.compileAlter(primaryBlueprint)[0]);
    }

    function testIncrementsWithPrimaryCommandMysql() {
        var blueprint = new Blueprint("tenant_users");
        blueprint.increments("id");
        blueprint.unsignedBigInteger("tenant_id");
        blueprint.primary(["id", "tenant_id"]);

        Assert.equals(
            "CREATE TABLE `tenant_users` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, "
            + "`tenant_id` BIGINT UNSIGNED NOT NULL, PRIMARY KEY (`id`, `tenant_id`))",
            mysql.compileCreate(blueprint)[0]);
    }

    function testFloatPrecisionMatchesLaravel() {
        var blueprint = new Blueprint("metrics");
        blueprint.float("wide");
        blueprint.float("narrow", 24);
        Assert.equals("CREATE TABLE `metrics` (`wide` FLOAT(53) NOT NULL, `narrow` FLOAT(24) NOT NULL)", mysql.compileCreate(blueprint)[0]);
        Assert.equals("CREATE TABLE `metrics` (`wide` FLOAT NOT NULL, `narrow` FLOAT NOT NULL)", sqlite.compileCreate(blueprint)[0]);
    }

    function testForeignModifiersRetainFluentType() {
        var blueprint = new Blueprint("posts");
        var column = blueprint.foreignId("user_id").nullable().defaultValue(null).index().comment("owner");
        column.constrained().cascadeOnDelete();
        Assert.isTrue(column.isNullable);
        Assert.isTrue(column.hasDefault);
        Assert.isTrue(mysql.compileCreate(blueprint)[0].indexOf("REFERENCES `users` (`id`) ON DELETE CASCADE") != -1);

        var uuid = new Blueprint("posts");
        uuid.foreignUuid("user_uuid").nullable().constrained(null, "uuid");
        Assert.isTrue(mysql.compileCreate(uuid)[0].indexOf("REFERENCES `users` (`uuid`)") != -1);
    }

    function testImplicitIndexNamesMatchLaravelCase() {
        var blueprint = new Blueprint("Users");
        blueprint.string("Email").unique();
        blueprint.index(["Email"]);
        blueprint.foreignId("Owner_id").constrained("users");
        var sql = mysql.compileCreate(blueprint).join("; ");
        Assert.isTrue(sql.indexOf("`users_email_unique`") != -1);
        Assert.isTrue(sql.indexOf("`users_email_index`") != -1);
        Assert.isTrue(sql.indexOf("`users_owner_id_foreign`") != -1);
        var drop = new Blueprint("Users");
        drop.dropUnique(["Email"]);
        drop.dropIndex(["Email"]);
        drop.dropForeign(["Owner_id"]);
        Assert.same([
            "ALTER TABLE `Users` DROP INDEX `users_email_unique`",
            "ALTER TABLE `Users` DROP INDEX `users_email_index`",
            "ALTER TABLE `Users` DROP FOREIGN KEY `users_owner_id_foreign`"
        ], mysql.compileAlter(drop));
    }

    function testSqliteIndexDefinitionPreserved() {
        Assert.equals("CREATE UNIQUE INDEX `new_name` ON t (lower(name) COLLATE NOCASE DESC) WHERE active = 1",
            SqliteTableDefinition.renameIndex('CREATE UNIQUE INDEX "old name" ON t (lower(name) COLLATE NOCASE DESC) WHERE active = 1', "new_name"));
        Assert.equals("CREATE INDEX IF NOT EXISTS /* name */ `new_name` ON t (a)",
            SqliteTableDefinition.renameIndex("CREATE INDEX IF NOT EXISTS /* name */ [old] ON t (a)", "new_name"));
        Assert.raises(() -> SqliteTableDefinition.renameIndex("CREATE TABLE t (a)", "new_name"), Exception);
        Assert.raises(() -> SqliteTableDefinition.renameIndex("CREATE INDEX old ON t (a)", "bad;name"), Exception);
        Assert.equals("value", SqliteTableDefinition.columnName("/* column */ -- note\n `value` INTEGER"));
        Assert.isTrue(SqliteTableDefinition.isPrimaryKeyConstraint("/* key */ CONSTRAINT /* name */ pk PRIMARY KEY (a)"));
    }

    function testSqliteTableDefinitionParse() {
        var definition = SqliteTableDefinition.parse(
            "CREATE TABLE \"orders\" (`id` INTEGER NOT NULL, "
            + "`status` VARCHAR CHECK (`status` IN ('a,b', 'c)')) NOT NULL, "
            + "[note] TEXT DEFAULT 'x''y', "
            + "\"weird\"\"name\" INTEGER, "
            + "\"check\" INTEGER, "
            + "CONSTRAINT `orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`), "
            + "CONSTRAINT \"orders_pk\" PRIMARY KEY (`id`)) WITHOUT ROWID");

        Assert.equals(7, definition.items.length);
        Assert.equals("id", SqliteTableDefinition.columnName(definition.items[0]));
        Assert.equals("`status` VARCHAR CHECK (`status` IN ('a,b', 'c)')) NOT NULL", definition.items[1]);
        Assert.equals("status", SqliteTableDefinition.columnName(definition.items[1]));
        Assert.equals("note", SqliteTableDefinition.columnName(definition.items[2]));
        Assert.equals("weird\"name", SqliteTableDefinition.columnName(definition.items[3]));
        Assert.equals("check", SqliteTableDefinition.columnName(definition.items[4]));
        Assert.isNull(SqliteTableDefinition.columnName(definition.items[5]));
        Assert.isFalse(SqliteTableDefinition.isPrimaryKeyConstraint(definition.items[5]));
        Assert.isNull(SqliteTableDefinition.columnName(definition.items[6]));
        Assert.isTrue(SqliteTableDefinition.isPrimaryKeyConstraint(definition.items[6]));
        Assert.equals("WITHOUT ROWID", definition.suffix);

        var plain = SqliteTableDefinition.parse("CREATE TABLE t (a INTEGER, b TEXT, PRIMARY KEY (a, b))");
        Assert.equals(3, plain.items.length);
        Assert.equals("a", SqliteTableDefinition.columnName(plain.items[0]));
        Assert.isTrue(SqliteTableDefinition.isPrimaryKeyConstraint(plain.items[2]));
        Assert.equals("", plain.suffix);

        Assert.raises(() -> SqliteTableDefinition.parse("CREATE TABLE t"), Exception);
    }
}
