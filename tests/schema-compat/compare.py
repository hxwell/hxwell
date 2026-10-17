#!/usr/bin/env python3
"""Compare captured HxWell JVM/PHP output with the real Laravel 13.0.0 component.

MySQL: tokenize SQL, preserving identifiers and string literals. Only normalize
keyword case/spacing, quoted numeric defaults, optional ADD COLUMN/VIRTUAL,
independent CREATE index order and inline versus ALTER foreign-key declarations.
SQLite: execute DDL, compare column/index/FK metadata and constraint behavior.
The separate live workflow compares SchemaBuilder changes and data preservation.
"""
import json
import re
import sqlite3
import sys
from pathlib import Path

TOKEN = re.compile(r"\s+|'(?:''|[^'])*'|`(?:``|[^`])*`|[A-Za-z_][A-Za-z_0-9]*|[0-9]+(?:\.[0-9]+)?|[(),.*+\-/=]")


def tokens(sql):
    result = []
    position = 0
    for match in TOKEN.finditer(sql):
        assert match.start() == position, f"Unrecognized SQL: {sql[position:]}"
        position = match.end()
        token = match.group()
        if token.isspace():
            continue
        if token[0] not in "'`":
            token = token.lower()
        if result and result[-1] == 'default' and re.fullmatch(r"'-?[0-9]+(?:\.[0-9]+)?'", token):
            token = token[1:-1]
        if result and result[-1] == 'add' and token == 'column':
            continue
        if result and result[-1] == ')' and token == 'virtual':
            continue  # MySQL defaults a generated column to VIRTUAL.
        result.append(token)
    assert position == len(sql), f"Unrecognized SQL: {sql[position:]}"
    return result


def mysql(statements, creating):
    result = []
    for sql in statements:
        words = tokens(sql)
        if words[:2] != ['create', 'table']:
            result.append(words)
            continue
        table, depth, start, items = words[2], 0, 4, []
        for i in range(4, len(words) - 1):
            if words[i] == '(':
                depth += 1
            elif words[i] == ')':
                depth -= 1
            elif words[i] == ',' and depth == 0:
                items.append(words[start:i])
                start = i + 1
        items.append(words[start:-1])
        columns = []
        for item in items:
            if item[0] == 'constraint':
                result.append(['alter', 'table', table, 'add'] + item)
            else:
                if columns:
                    columns.append(',')
                columns.extend(item)
        result.append(words[:4] + columns + [')'])
    return sorted(result) if creating else result


def sqlite(statements, table):
    with sqlite3.connect(':memory:') as db:
        for sql in statements:
            db.execute(sql)
        columns = []
        for cid, name, kind, required, default, pk, hidden in db.execute(f'PRAGMA table_xinfo(`{table}`)').fetchall():
            if default is not None and default.upper() != 'CURRENT_TIMESTAMP':
                # Defaults are converted using the destination column's affinity.
                db.execute(f'CREATE TEMP TABLE default_probe (value {kind})')
                db.execute('INSERT INTO default_probe VALUES (' + default + ')')
                default = db.execute('SELECT value FROM default_probe').fetchone()[0]
                db.execute('DROP TABLE default_probe')
            columns.append((name, kind.upper(), required, default, pk, hidden))
        indexes = []
        for _, name, unique, origin, partial in db.execute(f'PRAGMA index_list(`{table}`)'):
            fields = list(db.execute(f'PRAGMA index_xinfo(`{name}`)'))
            indexes.append((name, unique, origin, partial, fields))
        foreign = sorted(tuple(row[1:]) for row in db.execute(f'PRAGMA foreign_key_list(`{table}`)'))
        checks = []
        if table == 'choices':
            db.execute('INSERT INTO choices (state) VALUES (?)', ('Open',))
            try:
                db.execute('INSERT INTO choices (state) VALUES (?)', ('Invalid',))
                checks.append(False)
            except sqlite3.IntegrityError:
                checks.append(True)
            checks.extend(db.execute('SELECT state, label FROM choices').fetchone())
        if table == 'generated':
            db.execute('INSERT INTO generated (value) VALUES (7)')
            checks.extend(db.execute('SELECT * FROM generated').fetchone())
        return dict(columns=columns, indexes=sorted(indexes), foreign=foreign, checks=checks)


def main():
    jvm, php, laravel = [json.loads(Path(name).read_text()) for name in sys.argv[1:]]
    assert jvm == {key: php[key] for key in ('mysql', 'sqlite')}, 'JVM/PHP grammar output differs'
    count = 0
    for driver in ('mysql', 'sqlite'):
        assert set(jvm[driver]) == set(laravel[driver]), f'{driver}: scenarios differ'
        for name, statements in jvm[driver].items():
            if driver == 'mysql':
                actual = mysql(statements, name != 'alter_users')
                expected = mysql(laravel[driver][name], name != 'alter_users')
            else:
                prefix = jvm[driver]['users'] if name == 'alter_users' else []
                reference_prefix = laravel[driver]['users'] if name == 'alter_users' else []
                table = 'users' if name == 'alter_users' else name
                actual = sqlite(prefix + statements, table)
                expected = sqlite(reference_prefix + laravel[driver][name], table)
            assert actual == expected, f'{driver}/{name}:\nHxWell: {actual}\nLaravel: {expected}'
            count += 1
    assert php['workflow'] == laravel['workflow'], f"Live workflow mismatch: {php['workflow']} != {laravel['workflow']}"
    assert php['workflow']['invalidForeign'] and php['workflow']['uniqueEnforced']
    assert php['workflow']['survivingPosts'] == 1
    print(f'PASS: {count} Laravel SQL/schema comparisons; JVM/PHP output identical; live SQLite workflow identical.')


if __name__ == '__main__':
    main()
