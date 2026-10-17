<?php
// Use an isolated Composer installation; no Laravel application or database server is required.
require $argv[1];
if (Composer\InstalledVersions::getVersion('illuminate/database') !== '13.0.0.0') {
    throw new RuntimeException('This comparison requires illuminate/database 13.0.0.');
}

use Illuminate\Database\MySqlConnection;
use Illuminate\Database\SQLiteConnection;
use Illuminate\Database\Schema\Blueprint;

$definitions = [
    'users' => function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('email')->unique();
        $table->integer('age')->nullable()->default(18);
        $table->boolean('active')->default(true);
        $table->timestamps();
        $table->softDeletes();
        $table->rememberToken();
    },
    'scalar_types' => function (Blueprint $table) {
        $table->increments('id');
        $table->tinyInteger('tiny');
        $table->smallInteger('small')->unsigned();
        $table->mediumInteger('medium');
        $table->bigInteger('big');
        $table->char('code', 4);
        $table->text('body');
        $table->mediumText('medium_body');
        $table->longText('long_body');
        $table->float('ratio');
        $table->double('distance');
        $table->decimal('price', 12, 3);
        $table->binary('payload');
        $table->json('metadata');
        $table->uuid();
        $table->ulid();
        $table->ipAddress();
        $table->macAddress();
    },
    'date_types' => function (Blueprint $table) {
        $table->date('day');
        $table->dateTime('moment');
        $table->dateTimeTz('moment_tz');
        $table->time('clock');
        $table->timeTz('clock_tz');
        $table->timestamp('created')->useCurrent();
        $table->timestampTz('updated')->useCurrentOnUpdate()->nullable();
        $table->year('year');
        $table->datetimes();
    },
    'choices' => function (Blueprint $table) {
        $table->id();
        $table->enum('state', ['Open', 'Closed'])->default('Open');
        $table->string('label')->default("O'Reilly");
    },
    'memberships' => function (Blueprint $table) {
        $table->unsignedBigInteger('user_id');
        $table->unsignedBigInteger('team_id');
        $table->primary(['user_id', 'team_id']);
        $table->index(['team_id', 'user_id']);
    },
    'attachments' => function (Blueprint $table) {
        $table->id();
        $table->morphs('owner');
        $table->nullableUuidMorphs('subject');
        $table->nullableUlidMorphs('actor');
    },
    'UsersCase' => function (Blueprint $table) {
        $table->id();
        $table->string('Email')->unique();
        $table->index(['Email'], 'ExactIndex');
    },
    'generated' => function (Blueprint $table) {
        $table->integer('value');
        $table->integer('doubled')->storedAs('value * 2')->nullable();
        $table->integer('tripled')->virtualAs('value * 3')->nullable();
    },
    'posts' => function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
        $table->foreignUuid('owner_uuid')->nullable()->constrained('owners', 'uuid')->nullOnDelete();
    },
];

$result = [];
// Only server identity is stubbed: all compilation uses the unmodified Laravel grammar.
$mysql = new class(null, 'compat') extends MySqlConnection {
    public function isMaria() { return false; }
    public function getServerVersion(): string { return '8.0.36'; }
};
foreach (['mysql' => $mysql,
          'sqlite' => new SQLiteConnection(new PDO('sqlite::memory:'))] as $driver => $connection) {
    $connection->useDefaultSchemaGrammar();
    foreach ($definitions as $name => $callback) {
        $blueprint = new Blueprint($connection, $name);
        $blueprint->create();
        $callback($blueprint);
        $result[$driver][$name] = $blueprint->toSql();
    }
    $blueprint = new Blueprint($connection, 'users');
    $blueprint->string('nickname', 100)->nullable();
    $blueprint->renameColumn('name', 'display_name');
    $blueprint->dropUnique(['email']);
    $result[$driver]['alter_users'] = $blueprint->toSql();
}

$connection = new SQLiteConnection(new PDO('sqlite::memory:'));
$schema = $connection->getSchemaBuilder();
$schema->enableForeignKeyConstraints();
$schema->create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->integer('age')->nullable();
});
$connection->insert('INSERT INTO users (name, email) VALUES (?, ?)', ['Ayse', 'ayse@example.com']);
$schema->create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
    $table->integer('score');
    $table->integer('doubled')->storedAs('score * 2')->nullable();
});
$connection->insert('INSERT INTO posts (user_id, score) VALUES (?, ?)', [1, 5]);
$connection->insert('INSERT INTO posts (user_id, score) VALUES (?, ?)', [null, 6]);
function rejects(callable $callback): bool {
    try { $callback(); return false; } catch (Throwable $e) { return true; }
}
$invalidForeign = rejects(fn () => $connection->insert('INSERT INTO posts (user_id, score) VALUES (?, ?)', [999, 1]));
$schema->table('users', fn (Blueprint $table) => $table->text('name')->nullable()->change());
$schema->table('users', fn (Blueprint $table) => $table->renameIndex('users_email_unique', 'email_unique'));
$uniqueEnforced = rejects(fn () => $connection->insert('INSERT INTO users (email) VALUES (?)', ['ayse@example.com']));
$connection->insert('INSERT INTO users (name, email) VALUES (?, ?)', [null, 'second@example.com']);
$schema->table('users', fn (Blueprint $table) => $table->renameColumn('age', 'years'));
$schema->dropColumns('users', ['years']);
$result['workflow'] = [
    'generatedColumns' => $schema->getColumnListing('posts'),
    'usersColumns' => $schema->getColumnListing('users'),
    'hasIndex' => $schema->hasIndex('users', 'email_unique'),
    'invalidForeign' => $invalidForeign,
    'uniqueEnforced' => $uniqueEnforced,
    'names' => array_map(fn ($row) => $row->name, $connection->select('SELECT name FROM users ORDER BY id')),
    'generated' => array_map(fn ($row) => (int) $row->doubled, $connection->select('SELECT doubled FROM posts ORDER BY id')),
];
$connection->delete('DELETE FROM users WHERE id = ?', [1]);
$result['workflow']['survivingPosts'] = count($connection->select('SELECT * FROM posts'));
echo json_encode($result, JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT), "\n";
