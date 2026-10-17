<div align="center">  
  <img src="template/project/public/hxwell.svg" alt="HxWell Logo" width="120"/>  
    
  **HxWell is Modern, Laravel-inspired cross-platform web framework for Haxe**  
  
  [![Haxe](https://img.shields.io/badge/Haxe-4.3+-orange.svg)](https://haxe.org/)
  [![License](https://img.shields.io/badge/license-Custom%20MIT-blue.svg)](LICENSE)
  [![Documentation](https://img.shields.io/badge/docs-latest-brightgreen.svg)](#documentation)
  [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hxwell/hxwell)
  [![Discord](https://img.shields.io/discord/1406250185943945316.svg?color=7289da)](https://discord.gg/KEB9A9VXhb)

</div>  
  
## Features  
  
- **Cross-Platform**: Deploy to JVM, C++, HashLink, PHP, and Neko  
- **Laravel-Inspired**: Familiar patterns and conventions for rapid development  
- **Type-Safe**: Full Haxe type system benefits with compile-time checks  
- **Modern Architecture**: Middleware pipeline, routing system, and modular design  
- **Database Abstraction**: Query builder with ORM-like model operations  
- **Session Management**: Session handling with UUID generation  
- **Static File Serving**: Optimized static http server
- **CLI Tools**: Comprehensive command-line interface for project management
  
## Installation  
  
```bash  
haxelib install hxwell
```

## Quick Start

### Create a New Project
```bash
haxelib run hxwell new my-app  
cd my-app
```

### Test
```bash
haxelib run hxwell test jvm
haxelib run hxwell test cpp
haxelib run hxwell test neko
```

### Build
```bash
haxelib run hxwell build jvm  
haxelib run hxwell build cpp  
haxelib run hxwell build php  
haxelib run hxwell build hl  
haxelib run hxwell build neko
```

## Query and HTTP security behavior

`select` accepts column identifiers, qualified columns, `*`, qualified wildcards,
and explicit aliases such as `users.id AS user_id`. SQL expressions must use
`selectRaw`, which replaces the projection and accepts value bindings:

```haxe
User.query.select(["users.id", "name AS name"]).where("id", userId).first();
User.query.selectRaw("id, ? AS name", displayName).where("id", userId).first();
```

Keep raw SQL expressions in application code; pass request values as bindings.
`count()` and `exists()` use their own projections and preserve the query's selection.

The raw Socket HTTP driver accepts fixed-length request bodies. It rejects
duplicate or invalid `Content-Length`, conflicting `Transfer-Encoding` and
`Content-Length`, and malformed headers with **400**, closing the connection.
Unsupported `Transfer-Encoding` (including chunked requests) receives **501** and
closes the connection. The configured body limit also applies to streaming routes.
These framing rules apply to the raw Socket driver; other drivers use their host
HTTP server's framing. Query parameters are percent-decoded once.

Response header names, values and status messages are validated before output.
Cookies reject control characters and delimiter injection, including changes made
after insertion into a response. Encode cookie values that contain spaces,
non-ASCII characters or cookie delimiters, or use encrypted cookies.

## Schema Builder and Laravel conventions

HxWell's schema API follows Laravel's `Schema` facade → connection-specific builder →
`Blueprint` / column definitions → database grammar structure. This is a Haxe
implementation of those patterns, not inheritance from PHP classes. MySQL and SQLite
grammars implement the shared subset below; this is not the complete Laravel migration
system or a drop-in implementation of every Laravel schema method.

```haxe
import hx.well.facades.Schema;

Schema.create("posts", table -> {
    table.id();
    table.foreignId("user_id").nullable().constrained("users").cascadeOnDelete();
    table.string("title");
    table.string("slug").unique();
    table.timestamps();
});

Schema.table("posts", table -> table.text("title").nullable().change());
```

The connection must already be registered with `hx.well.database.Connection.create`.
Use `Schema.connection("name")` for a named connection.

| Laravel convention | HxWell behavior |
| --- | --- |
| `Schema::create/table/drop`, `Blueprint`, fluent column definitions | Same responsibilities and callback structure, expressed in Haxe |
| `id`, integer/text/date types, `timestamps`, `softDeletes`, morphs, indexes and foreign keys | Shared SQL/schema behavior is checked against Laravel 13.0.0 |
| `nullable()->constrained()->cascadeOnDelete()` | `nullable().constrained().cascadeOnDelete()`; modifiers precede `constrained()` |
| `default(...)`, `enum(...)` | `defaultValue(...)`, `enumeration(...)` to avoid Haxe keywords |
| Generated index/constraint names | Lowercase `table_columns_type`; explicit names retain their case |
| `change()` | Re-specify desired column modifiers; existing explicit indexes remain |

Compatibility has explicit limits:

- Inferred foreign tables use the simple `user_id` → `users` convention. Supply the
  table explicitly for other plural forms, e.g. `constrained("people")` or
  `constrained("categories")`; Laravel uses a full inflector.
- SQLite supports column changes by rebuilding the table, preserving data, indexes,
  triggers, table constraints, generated columns and the autoincrement sequence.
  Changing a column replaces that column's declaration, so re-specify its modifiers.
  With foreign keys enabled, run column changes outside an enclosing transaction;
  HxWell rejects an unsafe rebuild rather than cascading deletion of related rows.
- SQLite index renaming preserves the original expression, collation, ordering and
  partial-index predicate. Implicit primary/unique indexes cannot be renamed.
- Adding/dropping foreign or primary keys on an existing SQLite table, SQLite set,
  full-text and spatial indexes, PostgreSQL/SQL Server grammars, and Laravel's
  migration runner are outside this implementation. Date/time precision and several
  optional Laravel method arguments are also not exposed.
- Schema execution uses Haxe's `sys.db` drivers. The current JVM driver stubs do not
  provide SQLite/MySQL connections: JVM checks cover SQL generation and the virtual
  thread runtime; live database checks run on PHP/SQLite. MySQL is checked at the SQL
  compilation level, without claiming verification against a running MySQL server.

Run the reproducible comparison with Haxe/haxelib dependencies, Java 21+, Python 3,
PHP 8.3+ with PDO SQLite, and Composer installed:

```bash
python3 tests/schema-compat/run.py
```

It installs `illuminate/database` **13.0.0** in a temporary directory, compiles the
same declarations to JVM and PHP, and compares 20 MySQL/SQLite scenarios with the
real Laravel component. MySQL comparison normalizes documented equivalent SQL
forms; SQLite comparison executes the DDL and checks metadata and constraints.
A live builder workflow additionally checks column changes, index/column renames,
column drops, retained rows, nullable foreign keys, uniqueness, generated columns
and cascade deletion. It uses isolated databases and does not modify application
data. An existing installation can be supplied with `--autoload /path/to/vendor/autoload.php`.

The unit suite includes further SQLite rollback and data-preservation regressions:
`bash tests/unit/run.sh php` and `bash tests/unit/run.sh jvm`. Enable
`-D security_socket_tests` when compiling the JVM suite to include the real HTTP
virtual-thread tests, including request smuggling, response splitting, persistent
connections and bounded streaming request bodies.

Reference: [Laravel schema documentation](https://laravel.com/docs/13.x/migrations),
[Blueprint 13.0.0](https://github.com/laravel/framework/blob/v13.0.0/src/Illuminate/Database/Schema/Blueprint.php),
[SQLite grammar 13.0.0](https://github.com/laravel/framework/blob/v13.0.0/src/Illuminate/Database/Schema/Grammars/SQLiteGrammar.php).

## Use as Static File Server
```bash
haxelib run hxwell up /path --start --port 3000
```

### `--host <ip>`
Specifies the host address to bind the server.
- Default: 127.0.0.1
- Example:  
  `haxelib run hxwell up /path --host 0.0.0.0`

### `--port <number>`
Specifies the port to start the server on.  
If the port is already in use, the next available one will be chosen automatically.
- Default: 3000
- Example:  
  `haxelib run hxwell up /path --port 8080`

### `--poolSize <number>`
Defines the connection pool size for the server.
- Default: 6
- Example:  
  `haxelib run hxwell up /path --poolSize 12`

### `--encode`
Enables HTTP response compression using **deflate**.
- Default: Disabled
- Example:  
  `haxelib run hxwell up /path --encode`

### `--start`
Automatically opens the server URL in the default browser after startup.
- Default: Disabled
- Example:  
  `haxelib run hxwell up /path --start`



## Dependencies
- [haxe-concurrent](https://github.com/vegardit/haxe-concurrent)
- [uuid](https://github.com/flashultra/uuid)

## Credits
- [vegardit](https://github.com/vegardit)
  - Thanks to [haxe-concurrent](https://github.com/vegardit/haxe-concurrent) for bringing Java's excellent concurrent structure!
- [flashultra](https://github.com/flashultra)
  - [uuid](https://github.com/flashultra/uuid)
- [m0rkeulv](https://github.com/m0rkeulv)
  - If it wasn't for [intellij-haxe](https://github.com/HaxeFoundation/intellij-haxe), maybe I would never have write any haxe project :(

## Projects
- [airpsx](https://github.com/barisyild/airpsx)
