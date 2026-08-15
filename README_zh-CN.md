# memos-litestream

[English](README.md) | 中文

用 Litestream 自动把 Memos 的 SQLite 数据库备份到 S3/B2 存储桶。[memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build) 的重构版本。

> Fly.io 部署见下方 [Fly.io 部署](#flyio-部署) 章节。
> Docker 镜像在本地和 Fly.io 上都能用。

基于 [usememos/memos](https://github.com/usememos/memos) 和 [litestream](https://github.com/benbjohnson/litestream)。

## 先决条件

- Docker
- [BackBlaze B2](https://www.backblaze.com/) 或 S3 兼容存储账户
  - [创建 B2 存储桶](https://litestream.io/guides/backblaze/#create-a-bucket) 并记下 _bucket-name_ 和 _endpoint-url_
  - [创建 B2 访问密钥](https://litestream.io/guides/backblaze/#create-a-user) 并获取 _access-key-id_ 和 _secret-access-key_
- （可选）Telegram Bot Token，用于 Memogram。详见 [usememos/telegram-integration](https://github.com/usememos/telegram-integration)。

## Litestream

本镜像内置 Litestream **v0.5.15**（由 v0.3.x 升级而来）。升级无需迁移，变化如下：

- **v0.3.x 的备份仍然可恢复。** Litestream v0.5.8+ 可以直接恢复旧版创建的数据库。
- **环境变量已更新。** 本镜像现在使用标准的 `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`。旧的 `LITESTREAM_ACCESS_KEY_ID` / `LITESTREAM_SECRET_ACCESS_KEY` 仍作为备选支持，但文档中已不再列出。
- **默认开启快照。** 配置每 24 小时创建一次快照，保留 7 天。恢复长期运行的数据库会更快。
- **配置格式变了。** 旧版 `replicas` 数组格式仍能解析，新版 `replica` 单对象格式是推荐写法。详情见[上游迁移指南](https://litestream.io/docs/migration)。

> 如果你从旧版镜像升级，现有的 S3 备份无需转换。拉取新镜像重启即可。

## 运行

> 镜像支持 linux/amd64 和 linux/arm64。
>
> 标签：`stable`、`stable-memogram`。
> `stable` 跟随最新版 Memos。`stable-memogram` 额外集成了 Telegram Bot。

功能组合：

| 方案 | Memos | Litestream | Memogram |
| :--: | :---: | :--------: | :------: |
| 1 | ✓ | ✓ | ✕ |
| 2 | ✓ | ✓ | ✓ |
| 3 | ✓ | ✕ | ✓ |
| 4 | ✓ | ✕ | ✕ |

### 方案 1：Memos + Litestream 备份

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e LITESTREAM_REPLICA_PATH=memos_prod.db \
-e LITESTREAM_REPLICA_BUCKET=your-bucket-name \
-e LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
-e AWS_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e AWS_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
ghcr.io/hu3rror/memos-litestream:stable
```

### 方案 2：Memos + Litestream + Telegram Bot

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e LITESTREAM_REPLICA_PATH=memos_prod.db \
-e LITESTREAM_REPLICA_BUCKET=your-bucket-name \
-e LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
-e AWS_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e AWS_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
-e BOT_TOKEN=your-bot-token \
ghcr.io/hu3rror/memos-litestream:stable-memogram
```

### 方案 3：Memos + Telegram Bot，无 Litestream

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e BOT_TOKEN=your-bot-token \
ghcr.io/hu3rror/memos-litestream:stable-memogram
```

### 方案 4：仅 Memos

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
ghcr.io/hu3rror/memos-litestream:stable
```

或直接使用官方镜像 `neosmemo/memos:stable`。

### 环境变量说明

| 变量 | 必须 | 默认值 | 说明 |
|------|------|--------|------|
| `LITESTREAM_REPLICA_BUCKET` | Litestream 需要 | — | S3/B2 存储桶名称 |
| `LITESTREAM_REPLICA_ENDPOINT` | Litestream 需要 | — | S3/B2 endpoint 地址 |
| `AWS_ACCESS_KEY_ID` | Litestream 需要 | — | S3/B2 访问密钥 ID |
| `AWS_SECRET_ACCESS_KEY` | Litestream 需要 | — | S3/B2 访问密钥 |
| `LITESTREAM_REPLICA_PATH` | 否 | `memos_prod.db` | 存储桶中的数据库文件名 |
| `BOT_TOKEN` | Memogram 需要 | — | Telegram Bot Token。仅 `stable-memogram` 镜像 |
| `MEMOS_TOKEN` | Memogram 需要 | — | Memos API Token。未设置时尝试使用第一个管理员用户的 token |
| `TG_ID` | Memogram 需要 | — | 允许使用 Bot 的 Telegram 用户 ID |
| `ALLOWED_USERNAMES` | 否 | — | 允许使用 Bot 的 Telegram 用户名列表（逗号分隔，不含 @）。留空则允许所有用户 |

更多 Litestream 配置见 [litestream.io](https://litestream.io/getting-started/)。

## 数据持久化和恢复

数据默认存放在 `~/.memos`，挂载为卷即可在重启后保留数据。

**自动恢复：**
- 启动时若本地数据库文件（`memos_prod.db`）不存在，会自动从 S3/B2 恢复。
- 若本地数据库已存在，则跳过恢复，防止意外覆盖。
- 要强制从 S3/B2 恢复，启动前删除本地数据库文件。**这会覆盖本地数据，请先备份。**

**注意：** 本项目**不支持**备份本地资源文件（如图片）。请改用 Memos 内置的外部存储。

## Fly.io 部署

### 方案 A：单容器（推荐，更简单）

所有进程由入口脚本统一管理，运行在同一个容器中，和本地 Docker 一样。`fly deploy` 直接可用。

```shell
# 1. 创建应用
fly launch --no-deploy --region ord

# 2. 设置 Litestream 密钥
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  AWS_ACCESS_KEY_ID=your-key-id \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# 3. 可选：Telegram Bot
fly secrets set BOT_TOKEN=your-bot-token

# 4. 部署（构建带 Telegram Bot 的镜像）
fly deploy --build-arg USE_MEMOGRAM=1
```

入口脚本负责数据库恢复、Memos 启动、Memogram（若设置了 BOT_TOKEN）。

> **注意：** 默认 `stable` 镜像不包含 Memogram。部署时传 `--build-arg USE_MEMOGRAM=1`，或在 `fly.toml` 中设置 `[build.args]` 使其永久生效。

> **注意：** Memogram 需要 Machine 一直运行。`fly launch` 生成的 `fly.toml` 在 `[http_service]` 下默认 `auto_stop_machines = 'stop'`，应用空闲时 Machine 会停机，bot 也就不再响应消息。部署前把 `auto_stop_machines` 改成 `'off'`。

### 方案 B：多容器 sidecar（进阶）

Memos、Litestream、Memogram 各自运行在独立容器中，共享同一台 Machine。使用 `cli-config.json`。

```shell
# 1. 创建应用
fly launch --no-deploy --region ord --dockerfile ./Dockerfile

# 2. 设置密钥（和方案 A 一样）
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  AWS_ACCESS_KEY_ID=your-key-id \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# 3. 可选：Telegram Bot
fly secrets set BOT_TOKEN=your-bot-token

# 4. 用多容器配置部署
fly machine run --machine-config cli-config.json \
  --port 5230:5230/tcp:http
```

**注意：** 这里不用 `fly deploy`。`fly machine run` 会创建一台含 3 个容器的 Machine。后续更新镜像需用 `fly machine update` 逐个更新，或重新构建后再次 `fly machine run`。

### 选哪个

| | 方案 A | 方案 B |
|---|:---:|:---:|
| 复杂度 | 低 | 较高 |
| `fly deploy` 可用 | ✅ | ❌（用 `fly machine run`） |
| Memos + Litestream | ✅ | ✅ |
| Memogram | ✅ | ✅ |
| 独立更新各容器 | ❌ | ✅（每个容器可单独更新） |
| 推荐给 | 所有人 | 想隔离 litestream/memogram 进程的用户 |

### 配置文件

- `fly.toml` — 应用和服务配置（方案 A 使用）
- `cli-config.json` — 多容器定义（方案 B 使用）

## 开发和构建

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
docker buildx build ./ --file ./Dockerfile --tag your-tag
```

构建带 Memogram 支持的镜像：

```shell
docker buildx build ./ --file ./Dockerfile --build-arg USE_MEMOGRAM=1 --tag your-tag:memogram
```

## 架构

容器启动时运行单个入口脚本（`entrypoint.sh`），负责：

1. **数据库恢复** — 如果配置了 Litestream（v0.5.15）且本地数据库不存在，从 S3/B2 恢复
2. **Memogram 启动** — 如果设置了 `BOT_TOKEN`，在后台等待 memos 端口就绪后启动 Memogram
3. **Memos 启动** — 通过 Litestream 复制（如果配置了）或直接启动 memos

不需要进程管理器（supervisor）。入口脚本通过 `exec` 将控制权交给 Litestream 或 Memos。

## 故障排查

### `fly deploy` 卡在 "Waiting for depot builder..."

Fly.io 的 Depot builder 有时无法启动，高峰期尤其常见。试试：

```shell
# 绕过 Depot，使用旧版远程构建
fly deploy --depot=false

# 或在本地构建后上传
fly deploy --local-only
```

如果仍然卡住，在 Fly.io Dashboard 中重置 builder：**Settings → App Builders → Reset**，或切换 builder region。

详见 [Fly.io 故障排查文档](https://fly.io/docs/getting-started/troubleshooting/)。

### `fly deploy` 报 "invalid tag" 错误

版本标签格式不对。直接运行 `fly deploy` 不带自定义标签，或用 GitHub Actions 时检查 `build-and-push.yml`。

## 从 Litestream v0.3.x 迁移

如果你从旧版镜像升级（Litestream v0.3.x → v0.5.x），以下是上游变更说明和注意事项。

### 上游变更摘要

| 变更项 | v0.3.x | v0.5.x | 影响 |
|--------|--------|--------|------|
| SQLite 驱动 | mattn/go-sqlite3（cgo） | modernc.org/sqlite（无 cgo） | 无需操作，二进制自包含 |
| 云 SDK | AWS SDK v1, Azure SDK v1 | AWS SDK v2, Azure SDK v2 | 透明，无需改配置 |
| 配置格式 | `replicas: [...]` 数组 | `replica:` 单对象 | 旧格式仍可解析，推荐新格式 |
| 快照配置 | 无 | `snapshot.interval` + `snapshot.retention` | 本镜像已自动添加 |
| 命令重命名 | `litestream wal` | `litestream ltx` | 仅影响手动 CLI，不影响 entrypoint |
| Age 加密 | 支持 | 已移除 | 本项目未使用 |
| v0.3.x 备份恢复 | — | 支持（v0.5.8+） | 现有备份可恢复 |

### 环境变量

Litestream v0.5.x 使用标准的 `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`。旧的 `LITESTREAM_ACCESS_KEY_ID` / `LITESTREAM_SECRET_ACCESS_KEY` 仍作为备选支持，但文档中已不再列出。

### 配置文件变化

`etc/litestream.yml` 从旧格式：

```yaml
dbs:
  - path: $DB_PATH
    replicas:
      - type: s3
        bucket: $LITESTREAM_REPLICA_BUCKET
        path: $LITESTREAM_REPLICA_PATH
        endpoint: $LITESTREAM_REPLICA_ENDPOINT
        force-path-style: true
```

改为新格式：

```yaml
snapshot:
  interval: 24h
  retention: 168h

dbs:
  - path: $DB_PATH
    replica:
      url: s3://$LITESTREAM_REPLICA_BUCKET/$LITESTREAM_REPLICA_PATH
      endpoint: $LITESTREAM_REPLICA_ENDPOINT
      force-path-style: true
```

新增的 `snapshot` 配置段每 24 小时创建一次压缩快照，保留 7 天。恢复数据库时直接使用最近快照，无需重放数月的 WAL 日志。

### 升级步骤

1. 拉取最新镜像：`docker pull ghcr.io/hu3rror/memos-litestream:stable`
2. 停止容器：`docker stop memos && docker rm memos`
3. 用同样的卷和环境变量重新启动

Litestream v0.5.x 会自动读取你现有的旧格式 S3 备份，继续正常复制。

## 项目维护状态

> ⚠️ **仅基础维护，按现状提供。**
>
> - 本项目按现状提供，仅做最低限度维护。使用风险自负。
> - 如果 Memos 上游发生重大架构调整，本项目将不再跟进更新。
> - 请自行对数据安全和备份负责。
> - 如需使用 Memos 最新功能或长期支持，请[迁移回官方镜像](#迁移回-memos-官方镜像)。

## 迁移回 Memos 官方镜像

如果不再需要 Litestream 或 Memogram，可以迁移回官方镜像（`ghcr.io/usememos/memos`）。

### 步骤

1. 停止并删除容器：
   ```shell
   docker stop memos && docker rm memos
   ```
2. 备份数据：
   ```shell
   cp -r ~/.memos ~/.memos_backup
   ```
3. 启动官方镜像：
   ```shell
   docker run -d \
     --name memos \
     --restart unless-stopped \
     -p 5230:5230 \
     -v ~/.memos:/var/opt/memos \
     ghcr.io/usememos/memos:latest
   ```
4. 打开 `http://localhost:5230` 验证数据。

**注意：** 官方镜像不包含 Memogram。如果依赖 Telegram Bot，需要单独部署。