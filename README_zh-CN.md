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

## 运行

> 镜像支持 linux/amd64 和 linux/arm64。
>
> 标签：`stable`、`stable-memogram`。
> `stable` 追踪最新版 Memos。`stable-memogram` 额外集成了 Telegram Bot。

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
-e LITESTREAM_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e LITESTREAM_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
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
-e LITESTREAM_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e LITESTREAM_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
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
| `LITESTREAM_REPLICA_ENDPOINT` | Litestream 需要 | — | S3/B2 终端地址 |
| `LITESTREAM_ACCESS_KEY_ID` | Litestream 需要 | — | S3/B2 访问密钥 ID |
| `LITESTREAM_SECRET_ACCESS_KEY` | Litestream 需要 | — | S3/B2 访问密钥 |
| `LITESTREAM_REPLICA_PATH` | 否 | `memos_prod.db` | 存储桶中的数据库文件名 |
| `BOT_TOKEN` | Memogram 需要 | — | Telegram Bot Token。仅 `stable-memogram` 镜像 |
| `MEMOS_TOKEN` | Memogram 需要 | — | Memos API Token。未设置时尝试使用第一个管理员用户的 token |
| `TG_ID` | Memogram 需要 | — | 允许使用 Bot 的 Telegram 用户 ID |
| `ALLOWED_USERNAMES` | 否 | — | 允许使用 Bot 的 Telegram 用户名列表（逗号分隔，不含 @）。留空则允许所有用户 |

更多 Litestream 配置见 [litestream.io](https://litestream.io/getting-started/)。

## 数据持久化和恢复

数据默认存储在 `~/.memos`，通过卷挂载持久化。

**自动恢复：**
- 启动时若本地数据库文件（`memos_prod.db`）不存在，会自动从 S3/B2 恢复。
- 若本地数据库已存在，则跳过恢复，防止意外覆盖。
- 要强制从 S3/B2 恢复，启动前删除本地数据库文件。**这会覆盖本地数据，请先备份。**

**注意：** 本项目**不支持**备份本地资源文件（如图片）。建议使用 Memos 内置的外部存储。

## Fly.io 部署

本项目包含 Fly.io 多容器 Machine 配置。Memos 和 Litestream 在同一台 Machine 中作为独立容器运行，共享 tmpfs 卷访问 SQLite 数据库。

### 部署步骤

```shell
# 创建应用
fly launch --no-deploy

# 设置密钥
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  LITESTREAM_ACCESS_KEY_ID=your-key-id \
  LITESTREAM_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# 可选：Telegram Bot
fly secrets set BOT_TOKEN=your-bot-token

# 部署
fly deploy
```

**注意：** `fly deploy` 只更新 memos 容器。Litestream 和 Memogram 容器仍使用旧镜像。要更新所有容器，请先用 `docker buildx build` 构建新镜像并推送，然后使用 `fly machine run --machine-config cli-config.json`。

### 配置文件

- `cli-config.json` — 容器定义（memos、litestream、memogram）
- `fly.toml` — 应用和服务配置

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

1. **数据库恢复** — 如果配置了 Litestream 且本地数据库不存在，从 S3/B2 恢复
2. **Memogram 启动** — 如果设置了 `BOT_TOKEN`，在后台等待 memos 端口就绪后启动 Memogram
3. **Memos 启动** — 通过 Litestream 复制（如果配置了）或直接启动 memos

不需要进程管理器（supervisor）。入口脚本通过 `exec` 将控制权交给 Litestream 或 memos，进程树简洁。

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