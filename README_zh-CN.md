# memos-litestream

[English](README.md) | 中文

✍️ 使用 litestream 自动备份还原 memos 的 SQLite 数据库到 B2/S3 Bucket。这个项目是 [memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build) 的重构版本，欢迎使用本项目！
> 如果您想要在 fly.io 上搭建运行，请访问 https://github.com/hu3rror/memos-on-fly 查看教程，本页面的教程是基于本地/服务器上运行的。

该项目基于 [usememos/memos](https://github.com/usememos/memos) 和 [litestream](https://github.com/benbjohnson/litestream) 。非常感谢！✨

## 前提条件
- Docker
- [BackBlaze B2](https://www.backblaze.com/) 或其他兼容 S3 API 服务的账户（默认模板基于 B2）
  - 创建 [BackBlaze B2 存储桶](https://litestream.io/guides/backblaze/#create-a-bucket) 并获取存储桶名称 Bucket name 和 endpoint url 
  - 创建 [BackBlaze B2 用户](https://litestream.io/guides/backblaze/#create-a-user) 并获取 ACCESS KEY ID 和 SECRET ACCESS KEY

## 安装

## 运行
> 该镜像支持 linux/amd64, linux/arm64, linux/arm/v7

!!! **运行请务必先编辑环境变量** !!!

```shell
docker run -d ghcr.io/hu3rror/memos-litestream:latest \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
--env LITESTREAM_REPLICA_PATH=memos_prod.db \
--env LITESTREAM_REPLICA_BUCKET=xxxxxxxxx \
--env LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
--env LITESTREAM_ACCESS_KEY_ID=000000001a2b3c40000000001 \
--env LITESTREAM_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0
```

或者使用本仓库中的 [docker-compose.yml](https://github.com/hu3rror/memos-litestream/blob/main/docker-compose.yml) 文件。

### 保持默认即可
- `LITESTREAM_REPLICA_PATH`

### 必须在运行前编辑
- `LITESTREAM_REPLICA_BUCKET`：将其修改为您的 S3/B2 存储桶名称
- `LITESTREAM_REPLICA_ENDPOINT`：将其修改为您的 S3/B2端点 URL
- `LITESTREAM_ACCESS_KEY_ID`：您的 S3/B2 访问密钥 ID
- `LITESTREAM_SECRET_ACCESS_KEY`：您的 S3/B2 密钥

更多关于 Litestream 的参考信息，请查看 https://litestream.io/getting-started/

## 注意事项
数据库文件默认在本机/服务器的 `~/.memos/` 目录中。

如果您误删了数据库文件，只需重启 Docker 容器，便会自动从 S3/B2 存储桶中重新下载数据库文件。

但是！该项目不支持备份和恢复您的本地资源（例如照片等），建议搭配 memos 自带的外部资源库功能使用 (个人不建议在没有额外备份手段的前提下在云服务器上使用本地资源库功能)

## 开发与构建

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
# 修改内容
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```
