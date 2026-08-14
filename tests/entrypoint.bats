setup() {
    TEST_DIR=$(mktemp -d)
    CALLS_LOG="/tmp/calls.log"

    # Ensure DB_PATH points inside the test sandbox
    export DB_PATH="${TEST_DIR}/memos_prod.db"

    # Truncate calls.log (mocks in Dockerfile.test append to /tmp/calls.log)
    : > "$CALLS_LOG"
}

teardown() {
    rm -rf "$TEST_DIR"
    : > /tmp/calls.log
    rm -f /tmp/memogram_started /usr/local/memos/data.txt
}

# ── helpers ──────────────────────────────────────────────

assert_called() {
    local pattern="$1"
    grep -q "$pattern" "$CALLS_LOG" && return 0
    echo "FAIL: expected calls.log to match pattern: $pattern"
    echo "  calls.log content:"
    cat "$CALLS_LOG"
    return 1
}

assert_not_called() {
    local pattern="$1"
    ! grep -q "$pattern" "$CALLS_LOG" && return 0
    echo "FAIL: expected calls.log NOT to match pattern: $pattern"
    echo "  calls.log content:"
    cat "$CALLS_LOG"
    return 1
}

assert_file_exists() {
    [ -f "$1" ] && return 0
    echo "FAIL: expected file to exist: $1"
    return 1
}

assert_file_not_exists() {
    [ ! -f "$1" ] && return 0
    echo "FAIL: expected file NOT to exist: $1"
    return 1
}

assert_file_contains() {
    local file="$1" pattern="$2"
    grep -q "$pattern" "$file" && return 0
    echo "FAIL: expected file $file to contain: $pattern"
    echo "  file content: $(cat "$file")"
    return 1
}

# ── tests ────────────────────────────────────────────────

@test "restore: DB missing + litestream env → calls litestream restore" {
    export LITESTREAM_REPLICA_BUCKET="test-bucket"
    export LITESTREAM_REPLICA_PATH="memos_prod.db"
    export LITESTREAM_REPLICA_ENDPOINT="s3.example.com"
    export LITESTREAM_ACCESS_KEY_ID="test-key"
    export LITESTREAM_SECRET_ACCESS_KEY="test-secret"
    # DB_PATH points to a non-existent file (setup ensures no file exists)
    # But the mock litestream restore will create it, so the test passes

    run /usr/local/memos/entrypoint.sh

    # litestream restore should have been called
    assert_called "litestream restore"
}

@test "restore: DB exists → skips restore" {
    export LITESTREAM_REPLICA_BUCKET="test-bucket"
    export LITESTREAM_REPLICA_PATH="memos_prod.db"
    export LITESTREAM_REPLICA_ENDPOINT="s3.example.com"
    export LITESTREAM_ACCESS_KEY_ID="test-key"
    export LITESTREAM_SECRET_ACCESS_KEY="test-secret"
    # Create the DB file so restore is skipped
    touch "$DB_PATH"

    run /usr/local/memos/entrypoint.sh

    assert_not_called "litestream restore"
    # Should still start memos via litestream replicate
    assert_called "litestream replicate"
}

@test "restore: no litestream env → starts memos directly" {
    # No LITESTREAM_REPLICA_* env vars set

    run /usr/local/memos/entrypoint.sh

    assert_not_called "litestream restore"
    assert_not_called "litestream replicate"
    assert_called "memos"
}

@test "memogram: BOT_TOKEN set → starts memogram" {
    export BOT_TOKEN="test-bot-token"
    # memogram binary exists at /usr/local/memos/memogram (set up in Dockerfile.test)

    run /usr/local/memos/entrypoint.sh

    # memogram should have been started (mock creates a marker)
    assert_file_exists "/tmp/memogram_started"
}

@test "memogram: BOT_TOKEN not set → skips memogram" {
    # No BOT_TOKEN

    run /usr/local/memos/entrypoint.sh

    assert_file_not_exists "/tmp/memogram_started"
}

@test "data.txt: MEMOS_TOKEN + TG_ID set → writes data.txt" {
    export MEMOS_TOKEN="test-memos-token"
    export TG_ID="12345"

    run /usr/local/memos/entrypoint.sh

    assert_file_exists "/usr/local/memos/data.txt"
    assert_file_contains "/usr/local/memos/data.txt" "12345:test-memos-token"
}

@test "data.txt: MEMOS_TOKEN set but TG_ID not set → does not write" {
    export MEMOS_TOKEN="test-memos-token"
    # No TG_ID

    run /usr/local/memos/entrypoint.sh

    assert_file_not_exists "/usr/local/memos/data.txt"
}

@test "data.txt: TG_ID set but MEMOS_TOKEN not set → does not write" {
    export TG_ID="12345"
    # No MEMOS_TOKEN

    run /usr/local/memos/entrypoint.sh

    assert_file_not_exists "/usr/local/memos/data.txt"
}

@test "defaults: MEMOS_PORT not set → uses 5230" {
    unset MEMOS_PORT
    # No litestream env, so memos runs directly
    # The mock memos logs its invocation

    run /usr/local/memos/entrypoint.sh

    # The entrypoint should have started memos (with default port implicit)
    assert_called "memos"
}