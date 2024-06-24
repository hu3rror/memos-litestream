# memos-litestream

[English](README.md) | 中文

> 如果你想在 fly.io 上直接运行，请访问 https://github.com/hu3rror/memos-on-fly ✈️
>
> Docker 镜像不仅在 fly.io 上可用，你也可以在本地运行它。

该项目基于 [usememos/memos](https://github.com/usememos/memos) 和 [litestream](https://github.com/benbjohnson/litestream)。非常感谢！✨

## 先决条件

- Docker
- [BackBlaze B2](https://www.backblaze.com/) / S3 兼容账户（默认模板是基于 B2 的）
  - [创建 BackBlaze B2 存储桶](https://litestream.io/guides/backblaze/#create-a-bucket) 并获取 _bucket-name_ / _endpoint-url_
  - [创建 BackBlaze B2 用户](https://litestream.io/guides/backblaze/#create-a-user) 并获取 _access-key-id_ / _secret-access-key_

## 运行

> 该镜像支持 linux/amd64、linux/arm64
>
> `stable`、`latest`、`test` 是可用的 Docker 镜像标签，这与 Memos 官方上游镜像的标签是一致的。
>
> `stable-memogram` 是本仓库独特的镜像标签，该镜像集成了通过 Telegram BOT 发送到 Memos 的实验性功能（），使用前需要自定义 `BOT_TOKEN` 环境变量。

本仓库的镜像有多种功能组合方案可选：

| 方案类型 | Memos | Litestream | Memogram |
| :--: | :---: | :--------: | :------: |
| 方案1  |   ✓   |     ✓      |    ✕     |
| 方案2  |   ✓   |     ✓      |    ✓     |
| 方案3  |   ✓   |     ✕      |    ✓     |
| 方案4  |   ✓   |     ✕      |    ✕     |

### 方案1 使用 Litestream 备份运行 Memos

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
ghcr.io/hu3rror/memos-litestream:stable # 标签为 stable
```

### 方案2 使用 Litestream 备份运行 Memos，并启用 Telegram BOT 功能

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
ghcr.io/hu3rror/memos-litestream:stable-memogram # 标签为 stable-memogram
```

### 方案3 运行 Memos，并启用 Telegram BOT 功能，但不使用 Litestream 备份数据库

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e BOT_TOKEN=your-bot-token \
ghcr.io/hu3rror/memos-litestream:stable-memogram # 标签为 stable-memogram
```

### 方案4 仅运行 Memos，不启用其他功能

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
ghcr.io/hu3rror/memos-litestream:stable # 标签为 stable 或直接使用 neosmemo/memos:stable
```

### 环境变量说明

- `LITESTREAM_REPLICA_PATH`: 你的数据库文件路径，保持默认即可
- `LITESTREAM_REPLICA_BUCKET`：你的 S3/B2 存储桶名称
- `LITESTREAM_REPLICA_ENDPOINT`：你的 S3/B2 终端点 URL
- `LITESTREAM_ACCESS_KEY_ID`：你的 S3/B2 Key ID
- `LITESTREAM_SECRET_ACCESS_KEY`：你的 S3/B2 密钥 ACCESS KEY
- `BOT_TOKEN`：你的 Telegram BOT token (仅限 `stable-memogram` 镜像使用)，官方项目：https://github.com/usememos/telegram-integration

有关 litestream 的更多信息，请参阅 https://litestream.io/getting-started/

## 注意事项

你的数据默认存储在 `~/.memos` 中。

如果不小心删除了数据，只需重新启动 Docker 容器，数据库文件将自动从你的 S3/B2 存储桶下载。

但是！该项目**不支持**备份和还原你的**本地资源**（例如照片等）！建议与 memos 的内置外部资源库一起使用（不建议在云 VM 上使用本地资源）。

## 开发和构建

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
# 根据需要进行修改
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```
