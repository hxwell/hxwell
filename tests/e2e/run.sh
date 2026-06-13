#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

TARGET="${1:?usage: run.sh <target> [driver]}"
DRIVER="${2:-socket}"
PORT="${PORT:-3210}"
BASE="http://127.0.0.1:$PORT"
ROOT="$(cd ../.. && pwd)"

cd server
rm -rf Export cache session .env

APP_KEY=$(openssl rand -base64 32)
cat > .env <<EOF
APP_NAME=e2e
APP_KEY=$APP_KEY
HOST=127.0.0.1
PORT=$PORT
HXWELL_DRIVER=$DRIVER
EOF

if [ "$TARGET" = "jvm" ] && [ "$DRIVER" = "undertow" ]; then
    mkdir -p java-lib
    MAVEN="https://repo1.maven.org/maven2"
    fetch_jar() {
        [ -f "java-lib/$1" ] || curl -sfL -o "java-lib/$1" "$MAVEN/$2"
    }
    fetch_jar "undertow-core-2.3.18.Final.jar" "io/undertow/undertow-core/2.3.18.Final/undertow-core-2.3.18.Final.jar"
    fetch_jar "xnio-api-3.8.16.Final.jar" "org/jboss/xnio/xnio-api/3.8.16.Final/xnio-api-3.8.16.Final.jar"
    fetch_jar "xnio-nio-3.8.16.Final.jar" "org/jboss/xnio/xnio-nio/3.8.16.Final/xnio-nio-3.8.16.Final.jar"
    fetch_jar "jboss-logging-3.4.3.Final.jar" "org/jboss/logging/jboss-logging/3.4.3.Final/jboss-logging-3.4.3.Final.jar"
    fetch_jar "wildfly-common-1.5.4.Final.jar" "org/wildfly/common/wildfly-common/1.5.4.Final/wildfly-common-1.5.4.Final.jar"
    fetch_jar "jboss-threads-3.5.0.Final.jar" "org/jboss/threads/jboss-threads/3.5.0.Final/jboss-threads-3.5.0.Final.jar"
fi

NEEDS_NODE_MODULES=0
if [ "$TARGET" = "js" ]; then
    NEEDS_NODE_MODULES=1
fi
if [ "$DRIVER" = "socket" ] || [ "$DRIVER" = "undertow" ]; then
    NEEDS_NODE_MODULES=1
fi
if [ "$NEEDS_NODE_MODULES" = "1" ]; then
    if [ -d node_modules/deasync ] && [ -d node_modules/ws ]; then
        :
    else
        npm install --no-fund --no-audit
    fi
fi

haxelib run hxwell build "$TARGET"

SERVER_PID=""
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
    pkill -f "hxwell.jar start" 2>/dev/null || true
    pkill -f "hxwell.n start" 2>/dev/null || true
    pkill -f "hxwell.js start" 2>/dev/null || true
    pkill -f "hxwell.hl start" 2>/dev/null || true
    pkill -f "HxWell start" 2>/dev/null || true
    pkill -f "hxwell.boot.php" 2>/dev/null || true
}
trap cleanup EXIT

case "$TARGET" in
    jvm)
        CLASSPATH="hxwell.jar"
        if [ "$DRIVER" = "undertow" ]; then
            rm -rf Export/jvm/java-lib
            cp -R java-lib Export/jvm/java-lib
            CLASSPATH="hxwell.jar:java-lib/*"
        fi
        cd Export/jvm
        java -cp "$CLASSPATH" hx.well.HxWell start &
        SERVER_PID=$!
        ;;
    neko)
        cd Export/neko
        neko hxwell.n start &
        SERVER_PID=$!
        ;;
    cpp)
        cd Export/cpp
        ./HxWell start &
        SERVER_PID=$!
        ;;
    hl)
        cd Export/hl
        hl hxwell.hl start &
        SERVER_PID=$!
        ;;
    js)
        cd Export/js
        node hxwell.js start &
        SERVER_PID=$!
        ;;
    php)
        cd Export/php
        php -S 127.0.0.1:$PORT hxwell.boot.php > /dev/null 2>&1 &
        SERVER_PID=$!
        ;;
    *)
        echo "unknown target: $TARGET (jvm|neko|cpp|hl|js|php)"
        exit 1
        ;;
esac

READY=0
for _ in $(seq 1 60); do
    if curl -s -o /dev/null --max-time 2 "$BASE/opt"; then
        READY=1
        break
    fi
    sleep 0.5
done

if [ "$READY" != "1" ]; then
    echo "FAIL server did not become ready on $BASE"
    exit 1
fi

FAIL=0

assert_body() {
    local method="${3:-GET}"
    local actual
    actual=$(curl -s -X "$method" "$BASE$1")
    if [ "$actual" = "$2" ]; then
        echo "PASS body $method $1 = $2"
    else
        echo "FAIL body $method $1: expected [$2] got [$actual]"
        FAIL=1
    fi
}

assert_status() {
    local method="${3:-GET}"
    local actual
    actual=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE$1")
    if [ "$actual" = "$2" ]; then
        echo "PASS status $method $1 = $2"
    else
        echo "FAIL status $method $1: expected [$2] got [$actual]"
        FAIL=1
    fi
}

assert_header() {
    local headers
    headers=$(curl -s -D - -o /dev/null ${4:+-X "$4"} "$BASE$1")
    if echo "$headers" | grep -qi "^$2:.*$3"; then
        echo "PASS header $1 $2: $3"
    else
        echo "FAIL header $1 $2: expected [$3] got:"
        echo "$headers" | grep -i "^$2:" || echo "  (header missing)"
        FAIL=1
    fi
}

assert_body_contains() {
    local actual
    actual=$(curl -s "$BASE$1")
    if echo "$actual" | grep -q "$2"; then
        echo "PASS contains $1 ~ $2"
    else
        echo "FAIL contains $1: expected fragment [$2] got [$actual]"
        FAIL=1
    fi
}

assert_body "/multi/foo/bar/baz" "foo-bar-baz"
assert_body "/opt/baris" "hello:baris"
assert_body "/opt" "hello:anon"
assert_body_contains "/json" '"hello":"world"'
assert_body_contains "/json" '"n":42'
assert_header "/json" "Content-Type" "application/json"
assert_header "/headers" "X-Test-Header" "hxwell"
assert_body "/echo" "posted" "POST"
assert_status "/echo" "405" "GET"
assert_header "/echo" "Allow" "Post" "GET"
assert_status "/abort/418" "418"
assert_status "/abort/503" "503"
assert_status "/abort/999" "404"
assert_status "/multi/a/b/c" "405" "POST"
assert_status "/yok-boyle-bir-yer" "404"
assert_body_contains "/index.html" "hxwell-e2e-index"

COOKIE_HEADERS=$(curl -s -D - -o /dev/null "$BASE/cookies" | grep -ci "^set-cookie" || true)
if [ "$COOKIE_HEADERS" -ge 3 ]; then
    echo "PASS cookies: $COOKIE_HEADERS separate Set-Cookie headers"
else
    echo "FAIL cookies: expected >=3 Set-Cookie headers, got $COOKIE_HEADERS"
    FAIL=1
fi

check() {
    if [ "$2" = "$3" ]; then
        echo "PASS $1"
    else
        echo "FAIL $1: expected [$2] got [$3]"
        FAIL=1
    fi
}

check "validation ok" "valid:ali" "$(curl -s -X POST -d 'name=ali' "$BASE/api/check")"
check "validation fails with 422" "422" "$(curl -s -o /dev/null -w '%{http_code}' -X POST -d 'other=1' "$BASE/api/check")"
check "api unknown method 404" "404" "$(curl -s -o /dev/null -w '%{http_code}' -X POST -d 'name=x' "$BASE/api/nope")"
check "api wrong verb 405" "405" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/check")"

COOKIE_JAR=$(mktemp)
curl -s -c "$COOKIE_JAR" "$BASE/session/set/hello42" > /dev/null
check "session roundtrip" "value:hello42" "$(curl -s -b "$COOKIE_JAR" "$BASE/session/get")"
check "session empty without cookie" "value:none" "$(curl -s "$BASE/session/get")"
rm -f "$COOKIE_JAR"

check "stream file" "stream-fixture-content" "$(curl -s "$BASE/stream")"
check "keep-alive reuse" "keepkeep" "$(curl -s "$BASE/keep" "$BASE/keep" | tr -d '\n')"

check "traversal blocked" "403" "$(curl -s --path-as-is -o /dev/null -w '%{http_code}' "$BASE/../../etc/passwd")"
check "dotfile blocked" "403" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/.env")"

if [ "$DRIVER" = "socket" ]; then
    DEFLATE_ENCODING=$(curl -s -D - -o /dev/null -H "Accept-Encoding: deflate" "$BASE/deflate" | grep -i "^content-encoding" | tr -d '\r' | awk '{print $2}')
    check "deflate encoding header" "deflate" "$DEFLATE_ENCODING"
    check "deflate body" "deflate-payload-deflate-payload-deflate-payload" "$(curl -s --compressed -H 'Accept-Encoding: deflate' "$BASE/deflate")"
    check "no deflate without accept" "deflate-payload-deflate-payload-deflate-payload" "$(curl -s "$BASE/deflate")"
fi

if [ "$DRIVER" = "socket" ] || [ "$DRIVER" = "undertow" ]; then
    RAW_STATUS=$(bash -c "exec 3<>/dev/tcp/127.0.0.1/$PORT; printf 'GARBAGE NONSENSE\r\n\r\n' >&3; read -t 5 -r line <&3; echo \"\$line\"" 2>/dev/null | tr -d '\r')
    if echo "$RAW_STATUS" | grep -q " 400 "; then
        echo "PASS malformed request returns 400"
    else
        echo "FAIL malformed request: got [$RAW_STATUS]"
        FAIL=1
    fi

    if command -v node > /dev/null; then
        if node ../../ws-client.js "ws://127.0.0.1:$PORT/ws" "merhaba-$$"; then
            echo "PASS websocket echo"
        else
            echo "FAIL websocket echo"
            FAIL=1
        fi
    fi
fi

CONC_MISMATCH=$(mktemp)
rm -f "$CONC_MISMATCH"
CONC_PIDS=""
for i in $(seq 1 30); do
    (
        body=$(curl -s "$BASE/multi/a$i/b$i/c$i")
        if [ "$body" != "a$i-b$i-c$i" ]; then
            echo "$i:[$body]" >> "$CONC_MISMATCH"
        fi
    ) &
    CONC_PIDS="$CONC_PIDS $!"
done
# Wait only on the curl jobs, not the long-running server child.
wait $CONC_PIDS
if [ -f "$CONC_MISMATCH" ]; then
    echo "FAIL concurrency: $(cat "$CONC_MISMATCH" | tr '\n' ' ')"
    rm -f "$CONC_MISMATCH"
    FAIL=1
else
    echo "PASS concurrency: 30 parallel requests"
fi

if [ "$FAIL" = "0" ]; then
    echo "E2E OK: $TARGET/$DRIVER"
else
    echo "E2E FAILED: $TARGET/$DRIVER"
fi
exit $FAIL
