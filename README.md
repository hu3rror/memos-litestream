# memos-litestream

English | [中文](README_zh-CN.md)

Utilize litestream for the automatic backup and restoration of the SQLite database of memos to a B2/S3 Bucket. This initiative represents a restructured iteration of [memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build). Feel free to employ this undertaking at your convenience.

> To directly execute on fly.io, kindly refer to https://github.com/hu3rror/memos-on-fly ✈️
>
> The Docker image is accessible not only on fly.io but also for local execution.

This endeavor is grounded in [usememos/memos](https://github.com/usememos/memos) and [litestream](https://github.com/benbjohnson/litestream). Much appreciation! ✨

## Prerequisites

- Docker
- [BackBlaze B2](https://www.backblaze.com/) / S3-compatible account (The default template is B2-based)
  - To [Create a BackBlaze B2 bucket](https://litestream.io/guides/backblaze/#create-a-bucket) and acquire the _bucket-name_ / _endpoint-url_
  - To [Create a BackBlaze B2 user](https://litestream.io/guides/backblaze/#create-a-user) and obtain the _access-key-id_ / _secret-access-key_

## How to run

> This image supports linux/amd64, linux/arm64.
>
> `stable`, `latest`, `test` are available Docker image tags, which are consistent with the tags of the official Memos upstream images.
>
> `stable-memogram` is a unique image tag in this repository. It integrates the experimental feature of sending messages to Memos via a Telegram bot. Customize the `BOT_TOKEN` environment variable before running.

This repository's images offer various feature combinations:

| Scheme | Memos | Litestream | Memogram |
| :---: | :---: | :---: | :---: |
| Scheme 1 | ✓ | ✓ | ✕ |
| Scheme 2 | ✓ | ✓ | ✓ |
| Scheme 3 | ✓ | ✕ | ✓ |
| Scheme 4 | ✓ | ✕ | ✕ |

### Scheme 1: Running Memos with Litestream Backup

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
ghcr.io/hu3rror/memos-litestream:stable # Tag is `stable`
```

### Scheme 2: Running Memos with Litestream Backup and Enabling Telegram BOT

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
ghcr.io/hu3rror/memos-litestream:stable-memogram # Tag is `stable-memogram`
```

### Scheme 3: Running Memos with Telegram BOT, but without Litestream Backup

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e BOT_TOKEN=your-bot-token \
ghcr.io/hu3rror/memos-litestream:stable-memogram # Tag is `stable-memogram`
```

### Scheme 4: Running Memos solely, without any other features

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
ghcr.io/hu3rror/memos-litestream:stable # Tag is `stable` or use official image `neosmemo/memos:stable`
```

### Environment Variable Explanation

- `LITESTREAM_REPLICA_PATH`: Your database file path, keep it default.
- `LITESTREAM_REPLICA_BUCKET`: Your S3/B2 bucket name.
- `LITESTREAM_REPLICA_ENDPOINT`: Your S3/B2 endpoint URL.
- `LITESTREAM_ACCESS_KEY_ID`: Your S3/B2 access key ID.
- `LITESTREAM_SECRET_ACCESS_KEY`: Your S3/B2 access key secret.
- `BOT_TOKEN`: Your Telegram BOT token, only for `stable-memogram` image. Official project: [usememos/telegram-integration](https://github.com/usememos/telegram-integration)

And for more information about litestream, see [https://litestream.io/getting-started/](https://litestream.io/getting-started/)

## Notes

Your data is stored in `~/.memos` by default.

In the event of accidental data deletion, restarting the docker container will trigger automatic downloading of the database file from your S3/B2 Bucket.

However, please note that this initiative **does not facilitate** the backup and restoration of your **local resources** (e.g., photos). It is recommended to use memos' built-in external resource libraries instead (Using local resources on a Cloud VM is not advisable.)

## Development and build

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
# modify as necessary
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```
