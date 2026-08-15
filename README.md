# memos-litestream

English | [中文](README_zh-CN.md)

Back up your memos SQLite database to S3/B2 with Litestream. A redesigned version of [memos-on-fly-build](https://github.com/hu3rror/memos-on-fly-build).

> For Fly.io deployment, see [Fly.io setup](#flyio-deployment) below.
> The Docker image works locally and on Fly.io.

Built on [usememos/memos](https://github.com/usememos/memos) and [litestream](https://github.com/benbjohnson/litestream).

## Prerequisites

- Docker
- A [BackBlaze B2](https://www.backblaze.com/) or S3-compatible account
  - [Create a bucket](https://litestream.io/guides/backblaze/#create-a-bucket) and note the _bucket-name_ and _endpoint-url_
  - [Create an app key](https://litestream.io/guides/backblaze/#create-a-user) and get the _access-key-id_ and _secret-access-key_
- (Optional) A Telegram Bot Token if using Memogram. See [usememos/telegram-integration](https://github.com/usememos/telegram-integration).

## Litestream

This image ships Litestream **v0.5.15** (upgraded from v0.3.x). The upgrade is transparent:

- **v0.3.x backups are still restorable.** Litestream v0.5.8+ can restore databases created by v0.3.x without any migration step.
- **Environment variables updated.** This image now uses the standard `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` names. The old `LITESTREAM_ACCESS_KEY_ID` / `LITESTREAM_SECRET_ACCESS_KEY` are still supported as fallbacks but no longer documented.
- **Snapshot by default.** The config now creates a snapshot every 24 hours and keeps them for 7 days. This speeds up recovery for long-running databases.
- **The config format changed.** If you maintain your own `litestream.yml`, the old `replicas` array format is still parsed but the new `replica` single-object format is recommended. See the [upstream migration guide](https://litestream.io/docs/migration) for details.

> If you're upgrading from an older version of this image, your existing S3 backups require no conversion. Just pull the new image and restart.

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
-e AWS_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e AWS_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
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
-e AWS_ACCESS_KEY_ID=000000001a2b3c40000000001 \
-e AWS_SECRET_ACCESS_KEY=K000ABCDEFGHiJkLmNoPqRsTuVwXyZ0 \
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
| `AWS_ACCESS_KEY_ID` | For Litestream | — | S3/B2 access key ID |
| `AWS_SECRET_ACCESS_KEY` | For Litestream | — | S3/B2 access key secret |
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

### Approach A: Single container (recommended, simpler)

All processes run in one container via the entrypoint script. Same as local Docker. `fly deploy` works normally.

```shell
# 1. Create the app
fly launch --no-deploy --region ord

# 2. Set Litestream credentials
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  AWS_ACCESS_KEY_ID=your-key-id \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# 3. Optional: Telegram bot
fly secrets set BOT_TOKEN=your-bot-token

# 4. Deploy (with Telegram bot support)
fly deploy --build-arg USE_MEMOGRAM=1
```

The entrypoint handles database restore, memos startup, and memogram (if BOT_TOKEN is set).

> **Note:** The default `stable` image does not include memogram. Pass `--build-arg USE_MEMOGRAM=1` to `fly deploy`, or set `[build.args]` in `fly.toml` to make it permanent.

> **Note:** Memogram needs the Machine to stay awake. The `fly.toml` that `fly launch` generates sets `auto_stop_machines = 'stop'`, so an idle Machine stops and the bot stops answering. Change it to `auto_stop_machines = 'off'` under `[http_service]` before deploying.

### Approach B: Multi-container sidecar (advanced)

Memos, litestream, and memogram each run in their own container, sharing the same Machine. Uses `cli-config.json`.

```shell
# 1. Create the app
fly launch --no-deploy --region ord --dockerfile ./Dockerfile

# 2. Set secrets (same as Approach A)
fly secrets set \
  LITESTREAM_REPLICA_BUCKET=your-bucket \
  LITESTREAM_REPLICA_ENDPOINT=s3.us-west-000.backblazeb2.com \
  AWS_ACCESS_KEY_ID=your-key-id \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  LITESTREAM_REPLICA_PATH=memos_prod.db

# 3. Optional: Telegram bot
fly secrets set BOT_TOKEN=your-bot-token

# 4. Deploy with multi-container config
fly machine run --machine-config cli-config.json \
  --port 5230:5230/tcp:http
```

**Note:** `fly deploy` is not used here. `fly machine run` creates a Machine with 3 containers. To update the image later, use `fly machine update` for each container or rebuild and re-run `fly machine run`.

### Which one to pick?

| | Approach A | Approach B |
|---|:---:|:---:|
| Complexity | Low | Higher |
| `fly deploy` works | ✅ | ❌ (use `fly machine run`) |
| Memos + Litestream | ✅ | ✅ |
| Memogram | ✅ | ✅ |
| Independent updates | ❌ | ✅ (each container can be updated separately) |
| Recommended for | All users | Users who want to isolate litestream/memogram processes |

### Configuration Files

- `fly.toml` — app and service config (works with Approach A)
- `cli-config.json` — multi-container definitions (for Approach B)

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

1. **Database restore** — if Litestream (v0.5.15) is configured and no local database exists, restores from S3/B2
2. **Memogram startup** — if `BOT_TOKEN` is set, starts Memogram in the background once the memos port is ready
3. **Memos launch** — runs memos through Litestream replication (if configured) or directly

No process manager (supervisor) is needed. The entrypoint uses `exec` to hand off to Litestream or memos directly.

## Troubleshooting

### `fly deploy` stuck on "Waiting for depot builder..."

Fly.io's Depot builder sometimes fails to start, especially during peak hours. Try:

```shell
# Skip Depot, use legacy remote builder
fly deploy --depot=false

# Or build locally and upload
fly deploy --local-only
```

If the problem persists, reset the builder in your Fly.io organization dashboard: **Settings → App Builders → Reset**. Or switch to a different builder region.

See [Fly.io troubleshooting docs](https://fly.io/docs/getting-started/troubleshooting/) for more.

### `fly deploy` fails with "invalid tag"

The version tag format is wrong. Run `fly deploy` without custom tags, or check the `build-and-push.yml` if using GitHub Actions.

## Migrating from Litestream v0.3.x

If you're upgrading the Litestream binary inside this image from v0.3.x to v0.5.x, here's what changed and what you need to know:

### What changed upstream

| Change | v0.3.x | v0.5.x | Impact |
|--------|--------|--------|--------|
| SQLite driver | mattn/go-sqlite3 (cgo) | modernc.org/sqlite (no cgo) | No action needed — the binary is self-contained |
| Cloud SDK | AWS SDK v1, Azure SDK v1 | AWS SDK v2, Azure SDK v2 | Transparent, no config change |
| Config format | `replicas: [...]` array | `replica:` single object | Old format still works, new format recommended |
| Snapshot config | Not available | `snapshot.interval` + `snapshot.retention` | Added automatically in this image |
| Command rename | `litestream wal` | `litestream ltx` | Only affects manual CLI usage, not the entrypoint |
| Age encryption | Supported | Removed | Not used by this project |
| v0.3.x restore | — | Supported (v0.5.8+) | Your existing backups are recoverable |

### Environment variables

Litestream v0.5.x uses the standard `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`. The old `LITESTREAM_ACCESS_KEY_ID` / `LITESTREAM_SECRET_ACCESS_KEY` are still supported as fallbacks but no longer documented.

### Config file change

In `etc/litestream.yml`, the old format:

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

Has been replaced with:

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

The `snapshot` section creates a compact snapshot every 24 hours and keeps them for 7 days. This avoids replaying months of WAL to restore a database — the latest snapshot is used instead.

### Upgrading

1. Pull the latest image: `docker pull ghcr.io/hu3rror/memos-litestream:stable`
2. Stop your container: `docker stop memos && docker rm memos`
3. Start it again with the same volume and env vars

That's it. Litestream v0.5.x will read your existing S3 backups in the old format and continue replicating normally.

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