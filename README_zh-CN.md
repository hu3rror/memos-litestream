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

## 安装

### 运行

> 该镜像支持 linux/amd64、linux/arm64、linux/arm/v7
>
> `stable`、`latest`、`test` 是可用的 Docker 镜像标签。

!!! **在运行之前务必编辑环境变量** !!!

```shell
docker run -d ghcr.io/hu3rror/memos-litestream:stable \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
--env LITESTREAM_REPLICA_PATH=memos_prod.db \
--env LITESTREAM_REPLICA_BUCKET=xxxxxxxxx \
--env LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
--env LITESTREAM_ACCESS_KEY_ID=000000001a2b3c40000000001 \
--env LITESTREAM_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0
```

或者使用存储库中的 [docker-compose.yml](./docker-compose.yml)。

### 保留默认设置

- `LITESTREAM_REPLICA_PATH`

### 运行前必须编辑

- `LITESTREAM_REPLICA_BUCKET`：修改为你的 S3/B2 存储桶名称
- `LITESTREAM_REPLICA_ENDPOINT`：修改为你的 S3/B2 终端点 URL
- `LITESTREAM_ACCESS_KEY_ID`：你的 S3/B2 访问密钥 ID
- `LITESTREAM_SECRET_ACCESS_KEY`：你的 S3/B2 秘密访问密钥

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
