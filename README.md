# memos-litestream

English | [中文](README_zh-CN.md)

✍️ Use litestream to automatically backup and restore memos' SQLite database to B2/S3 Bucket. This project is a refactored version of [memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build). Feel free to use this project! 🆓

> If you wanna run on fly.io directly, please visit https://github.com/hu3rror/memos-on-fly ✈️
> 
> The Docker image is not only available on fly.io, you can also run it locally.

This project is based on [usememos/memos](https://github.com/usememos/memos) and [litestream](https://github.com/benbjohnson/litestream). Thank you very much! ✨

## Prerequisites
- Docker
- [BackBlaze B2](https://www.backblaze.com/) / S3-compatible account (The default template is B2-based)
  -  To [Create a BackBlaze B2 bucket](https://litestream.io/guides/backblaze/#create-a-bucket) and you can get *bucket name* / *endpoint url*
  -  To [Create a BackBlaze B2 user](https://litestream.io/guides/backblaze/#create-a-user) and you can get *access-key-id* / *secret-access-key* 

## Installation

## RUN
> The image supports linux/amd64, linux/arm64, linux/arm/v7

!!! **Make sure to edit the environment variables before running** !!!

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

or use [docker-compose.yml](https://github.com/hu3rror/memos-litestream/blob/main/docker-compose.yml) in this repo.

### Keep the default
- `LITESTREAM_REPLICA_PATH`

### Must edit before running
- `LITESTREAM_REPLICA_BUCKET`: Modify to your S3/B2 bucket name
- `LITESTREAM_REPLICA_ENDPOINT`: Modify to your S3/B2 endpoint url
- `LITESTREAM_ACCESS_KEY_ID`: Your S3/B2 access-key-id
- `LITESTREAM_SECRET_ACCESS_KEY`: Your S3/B2 secret-access-key

For more information about litestream, please see https://litestream.io/getting-started/

## Notes
Your data is store in `~/.memos` by default.

If you delete your data by mistake, you can just restart your docker container, and your database file will be downloaded automatically from your S3/B2 Bucket.

BUT! This project **does not support** backing up and restoring your **local resources** (your photos etc.)! Recommended for use with memos' built-in external resource libraries (It is not recommended to use local resource on Cloud VM. )

## Development and build

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
# modify something
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```
