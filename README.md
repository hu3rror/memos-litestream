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

## Installation

### RUN

> The image supports linux/amd64, linux/arm64
>
> `stable`, `latest`, `test`, `stable-memogram` are accessible docker image tags. `stable-memogram` integrates the function of being sent to Memos by telegram bot, you need to customize the `BOT_TOKEN` environment variable before using it, go to https://github.com/usememos/telegram-integration to get more details.

!!! **Ensure to modify the environment variables before execution** !!!

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
# --env BOT_TOKEN=0000000000000000000000000000000000000000
```

or utilize [docker-compose.yml](./docker-compose.yml) in the repository.

### Retain the default

- `LITESTREAM_REPLICA_PATH`

### Essential modifications before execution

- `LITESTREAM_REPLICA_BUCKET`: Adjust to your S3/B2 bucket name
- `LITESTREAM_REPLICA_ENDPOINT`: Adjust to your S3/B2 endpoint url
- `LITESTREAM_ACCESS_KEY_ID`: Your S3/B2 access-key-id
- `LITESTREAM_SECRET_ACCESS_KEY`: Your S3/B2 secret-access-key

For additional insights into litestream, please consult https://litestream.io/getting-started/

### Optional modifications before execution

- `BOT_TOKEN`: Your telegram bot token

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
