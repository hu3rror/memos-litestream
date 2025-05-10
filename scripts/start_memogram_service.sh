#!/bin/sh
set -e

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MemogramService] $1"
}

# Function to check if the required environment variables for Memogram are set.
use_memogram_check() {
    [ -x /usr/local/memos/memogram ] && [ -n "$BOT_TOKEN" ]
}

cd /usr/local/memos #确保在正确的工作目录

if ! use_memogram_check; then
    log "[INFO] Memogram prerequisites not met (executable missing or BOT_TOKEN not set). Memogram will not start."
    # 正常退出，supervisor 不会认为这是错误，也不会无限重启
    # 如果希望 supervisor 在条件不满足时不要尝试启动，可以在 run.sh 中动态生成 supervisor 配置，但这更复杂
    exit 0
fi

log "[INFO] Found BOT_TOKEN, now attempt to start Memogram service."

# 等待 memos 启动并创建数据库文件
# 使用 nc (netcat) 或类似工具检查 memos 端口是否可达可能更可靠
# 但 pgrep 和文件检查也是一种方法
timeout=120 # 增加超时时间
attempt=0
max_attempts=$((timeout / 5))

while [ $attempt -lt $max_attempts ]; do
    # 检查 memos 进程是否存在。注意：pgrep 可能需要 procps 包
    # 并且 memos 进程名可能需要精确匹配
    if pgrep -x "memos" >/dev/null; then
        log "[INFO] Memos process detected."
        # 进一步检查 DB_PATH 是否存在，因为 memos 可能仍在初始化
        if [ -f "$DB_PATH" ]; then
            log "[INFO] Database file $DB_PATH found. Now starting Memogram service."
            exec /usr/local/memos/memogram # 使用 exec 替换当前 shell
        else
            log "[WARNING] Memos process running, but DB_PATH $DB_PATH not yet found. Waiting..."
        fi
    else
        log "[WARNING] Memos process not detected. Waiting..."
    fi
    sleep 5
    attempt=$((attempt + 1))
done

log "[ERROR] Timeout ($timeout seconds) reached. Memos service not fully ready or DB_PATH not found. Memogram will not start."
exit 1 # 错误退出，supervisor 会尝试重启 (根据 autorestart=true)
