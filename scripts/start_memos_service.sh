#!/bin/sh
set -e

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MemosService] $1"
}

# Function to check if the required environment variables for Litestream are set.
use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && \
    [ -n "$LITESTREAM_REPLICA_PATH" ] && \
    [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && \
    [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && \
    [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

cd /usr/local/memos #确保在正确的工作目录

if use_litestream; then
    log "[INFO] Now starting Memos service with Litestream."
    # exec litestream replicate -exec "./memos --mode ${MEMOS_MODE} --port ${MEMOS_PORT}"
    # Litestream 的 -exec 会将 memos 的 stdout/stderr 传递给 litestream，然后 litestream 再传递给 supervisor
    # 确保 memos 使用环境变量或配置文件来获取其设置，而不是依赖这里的参数（除非你确定这些参数总是固定的）
    # memos 默认会监听 0.0.0.0:$MEMOS_PORT
    exec /usr/local/bin/litestream replicate -exec "/usr/local/memos/memos"
else
    log "[INFO] Now starting Memos service directly."
    exec /usr/local/memos/memos
fi
