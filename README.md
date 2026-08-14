# memos-litestream

English | [中文](README_zh-CN.md)

Back up your memos SQLite database to S3/B2 with Litestream, automatically. A redesigned version of [memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build).

> For Fly.io deployment, see [Fly.io setup](#flyio-deployment) below.
> The Docker image works locally and on Fly.io.

Built on [usememos/memos](https://github.com/usememos/memos) and [litestream](https://github.com/benbjohnson/litestream).

## Prerequisites

- Docker
- A [BackBlaze B2](https://www.backblaze.com/) or S3-compatible account
  - [Create a bucket](https://litestream.io/guides/backblaze/#create-a-bucket) and note the _bucket-name_ and _endpoint-url_
  - [Create an app key](https://litestream.io/guides/backblaze/#create-a-user) and get the _access-key-id_ and _secret-access-key_
- (Optional) A Telegram Bot Token if using Memogram. See [usememos/telegram-integration](https://github.com/usememos/telegram-integration).

## How to run

> The image supports linux/amd64 and linux/arm64.
>
> Tags: `stable`, `stable-memogram`.
> `stable` tracks the latest memos release. `stable-memogram` adds the Telegram bot integration.

Available feature combinations:

| Scheme | Memos | Litestream | Memogram |
| :---: | :---: | :---: | :---: |
| 1 | ✓ | ✓ | ✕ |
| 2 | ✓ | ✓ | ✓ |
| 3 | ✓ | ✕ | ✓ |
| 4 | ✓ | ✕ | ✕ |

### Scheme 1: Memos + Litestream backup

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

### Scheme 2: Memos + Litestream + Telegram bot

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

### Scheme 3: Memos + Telegram bot, no Litestream

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
-e BOT_TOKEN=your-bot-token \
ghcr.io/hu3rror/memos-litestream:stable-memogram
```

### Scheme 4: Memos only

```shell
docker run -d \
--name memos \
-p 5230:5230 \
-v ~/.memos/:/var/opt/memos \
ghcr.io/hu3rror/memos-litestream:stable
```

Or use the official image `neosmemo/memos:stable`.

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LITESTREAM_REPLICA_BUCKET` | For Litestream | — | S3/B2 bucket name |
| `LITESTREAM_REPLICA_ENDPOINT` | For Litestream | — | S3/B2 endpoint URL |
| `LITESTREAM_ACCESS_KEY_ID` | For Litestream | — | S3/B2 access key ID |
| `LITESTREAM_SECRET_ACCESS_KEY` | For Litestream | — | S3/B2 access key secret |
| `LITESTREAM_REPLICA_PATH` | No | `memos_prod.db` | Database file name in the bucket |
| `BOT_TOKEN` | For Memogram | — | Telegram bot token. Only for `stable-memogram` image |
| `MEMOS_TOKEN` | For Memogram | — | Memos API token. If not set, Memogram tries the first admin user's token |
| `TG_ID` | For Memogram | — | Telegram user ID allowed to use the bot |
| `ALLOWED_USERNAMES` | No | — | Comma-separated Telegram usernames allowed to use the bot. Omit or leave empty to allow all users. Usernames without @ |

See [litestream.io](https://litestream.io/getting-started/) for more about Litestream configuration.

## Data Persistence and Restoration

Data lives in `~/.memos` by default. Mount it as a volume to keep data across restarts.

**Automatic restore:**
- If no local database (`memos_prod.db`) exists at startup, the entrypoint attempts to restore from S3/B2.
- If a local database exists, the restore is skipped. This prevents accidental overwrites.
- To force a restore from S3/B2, delete the local database file before starting the container. **This will overwrite your local data. Back up first.**

**Note:** This project does **not** back up local resource files (e.g., photos). Use memos' built-in external storage instead.

## Fly.io Deployment

This project includes a multi-container Machine configuration for Fly.io. Memos and Litestream run as separate containers in the same Machine, sharing a tmpfs volume for the SQLite database.

### Setup

```shell
# Create the app
fly launch --no-deploy

# Set secrets
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  LITESTREAM_ACCESS_KEY_ID=your-key-id \
  LITESTREAM_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# Optional: Telegram bot
fly secrets set BOT_TOKEN=your-bot-token

# Deploy
fly deploy
```

**Note:** `fly deploy` only updates the memos container. Litestream and Memogram containers keep their old image references. To update all containers, use `fly machine run --machine-config cli-config.json` after building and pushing a new image.

### Configuration Files

- `cli-config.json` — container definitions (memos, litestream, memogram)
- `fly.toml` — app and service configuration

## Development and Build

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
docker buildx build ./ --file ./Dockerfile --tag your-tag
```

To build with Memogram support:

```shell
docker buildx build ./ --file ./Dockerfile --build-arg USE_MEMOGRAM=1 --tag your-tag:memogram
```

## Architecture

The container runs a single entrypoint script (`entrypoint.sh`) that handles:

1. **Database restore** — if Litestream is configured and no local database exists, restores from S3/B2
2. **Memogram startup** — if `BOT_TOKEN` is set, starts Memogram in the background once the memos port is ready
3. **Memos launch** — runs memos through Litestream replication (if configured) or directly

No process manager (supervisor) is needed. The entrypoint uses `exec` to hand off to Litestream or memos directly, keeping the process tree simple.

## Maintenance Status

> ⚠️ **Basic maintenance only, as-is.**
>
> - This project is provided as-is with minimal maintenance. Use at your own risk.
> - If the upstream memos project undergoes major changes, I will not push compatibility updates.
> - You are responsible for your own data safety and backups.
> - If you need the latest memos features or long-term support, [migrate back to the official image](#migrating-back-to-official-memos-image).

## Migrating Back to Official Memos Image

If you no longer need Litestream or Memogram, switch to the official image (`ghcr.io/usememos/memos`).

### Steps

1. Stop and remove the container:
   ```shell
   docker stop memos && docker rm memos
   ```
2. Back up your data:
   ```shell
   cp -r ~/.memos ~/.memos_backup
   ```
3. Run the official image:
   ```shell
   docker run -d \
     --name memos \
     --restart unless-stopped \
     -p 5230:5230 \
     -v ~/.memos:/var/opt/memos \
     ghcr.io/usememos/memos:latest
   ```
4. Open `http://localhost:5230` to verify your data.

**Note:** The official image does not include Memogram. If you rely on the Telegram bot, host it separately.