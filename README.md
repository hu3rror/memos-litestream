# memos-litestream
✍️ Run memos binary with litestream. Not only available on fly.io, you can run it locally.
> If you wanna run on fly.io directly, please visit https://github.com/hu3rror/memos-on-fly

This project is based on [usememos/memos](https://github.com/usememos/memos) and the build-artifacts binary download link conversion service is provided by [nightly.link](https://github.com/oprypin/nightly.link). Thank you very much! ✨

## Prerequisites
- Docker
- S3 / [BackBlaze B2](https://www.backblaze.com/) account (The default template is B2-based)
  -  To [Create a BackBlaze B2 bucket](https://litestream.io/guides/backblaze/#create-a-bucket) and get bucket name / endpoint url
  -  To [Create a BackBlaze B2 user](https://litestream.io/guides/backblaze/#create-a-user) and get access-key-id / secret-access-key 

## Installation

## RUN
> The image supports AMD64/ARM64

!!! **Be sure to edit the environment variables first** !!!

```shell
docker run -d ghcr.io/hu3rror/memos-litestream:latest \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
--env DB_PATH=/var/opt/memos/memos_prod.db \
--env LITESTREAM_REPLICA_PATH=memos_prod.db \
--env LITESTREAM_REPLICA_BUCKET=xxxxxxxxx \
--env LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
--env LITESTREAM_ACCESS_KEY_ID=000000001a2b3c40000000001 \
--env LITESTREAM_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0
```

or use [docker-compose.yml](https://github.com/hu3rror/memos-litestream/blob/main/docker-compose.yml) in this repo.

### It's better not to modify
- `DB_PATH`
- `LITESTREAM_REPLICA_PATH`

### Must edit before running
- `LITESTREAM_REPLICA_BUCKET`: Modify to your S3/B2 bucket name
- `LITESTREAM_REPLICA_ENDPOINT`: Modify to your S3/B2 endpoint url
- `LITESTREAM_ACCESS_KEY_ID`: Your S3/B2 access-key-id
- `LITESTREAM_SECRET_ACCESS_KEY`: Your S3/B2 secret-access-key

## Notes
Your data is store in `~/.memos`.

If you delete your data by mistake, you can just restart your docker container, and your database file will be downloaded automatically from your S3/B2 Bucket.

BUT! This project **does not support** backing up and restoring your **local resources** (your photos, etc.)!

## Development

```shell
git clone https://github.com/hu3rror/memos-litestream.git
```

```shell
cd memos-litestream
# modify something
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```

## Plan
- Support backing up local resource. 
