#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

TARGET="${1:-jvm}"

HAXE_MAJOR=$(haxe --version 2>&1 | cut -d. -f1)
EXTRA=""
if [ "$HAXE_MAJOR" -ge 5 ]; then
    EXTRA="-lib hx4compat"
fi

case "$TARGET" in
    jvm)
        haxe build.hxml $EXTRA -lib hxjava --jvm out/test.jar
        java -jar out/test.jar
        ;;
    neko)
        haxe build.hxml $EXTRA --neko out/test.n
        neko out/test.n
        ;;
    js)
        haxe build.hxml $EXTRA -lib hxnodejs -D js-es=6 -js out/test.js
        node out/test.js
        ;;
    php)
        haxe build.hxml $EXTRA --php out/php
        php out/php/index.php
        ;;
    cpp)
        haxe build.hxml $EXTRA -lib hxcpp --cpp out/cpp
        ./out/cpp/TestMain
        ;;
    hl)
        haxe build.hxml $EXTRA --hl out/test.hl
        hl out/test.hl
        ;;
    *)
        echo "unknown target: $TARGET (jvm|neko|js|php|cpp|hl)"
        exit 1
        ;;
esac
