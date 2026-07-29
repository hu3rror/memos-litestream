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
- (Optional) Telegram Bot Token if using Memogram.  See [usememos/telegram-integration](https://github.com/usememos/telegram-integration) for details.

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

### Understanding the Schemes

*   **Memos:** The core Memos application.
*   **Litestream:** Enables continuous SQLite database replication to a remote S3-compatible storage (like Backblaze B2) for backup and restoration.
*   **Memogram:** An experimental feature that allows you to send memos to your Memos instance via a Telegram bot.

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

### Scheme 2: Running Memos with Litestream Backup and Enabling Telegram BOT (Memogram)

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

### Scheme 3: Running Memos with Telegram BOT (Memogram), but without Litestream Backup

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
- `MEMOS_TOKEN`: Memos API token for Memogram to use.  If not set, Memogram will attempt to use the first admin user's token.
- `TG_ID`: Telegram User ID that will be allowed to use the bot.
- `ALLOWED_USERNAMES`: Allows you to restrict bot usage to specific Telegram users. When set, only users with usernames in this list will be able to interact with the bot (Usernames must not include the @ symbol). Leave empty or remove the variable if you want to allow all users. 

And for more information about litestream, see [https://litestream.io/getting-started/](https://litestream.io/getting-started/)

## Data Persistence and Restoration

Your data is stored in `~/.memos` by default. This directory is mounted as a volume in the Docker containers, ensuring data persistence across container restarts.

**Automatic Database Restoration:**

*   If a local database file (`$DB_PATH`, typically `memos_prod.db`) is *not* found when the container starts, Litestream will automatically attempt to restore the database from your configured S3/B2 bucket.
*   If a local database file *is* found, Litestream will *not* automatically restore from the bucket. This prevents accidental overwrites of your local data.
*   To force a restore from the bucket, delete the local database file *before* starting the container. **Warning:** This will overwrite your local data. Ensure you have a backup if needed.

In the event of accidental data deletion, restarting the docker container will trigger automatic downloading of the database file from your S3/B2 Bucket.

However, please note that this initiative **does not facilitate** the backup and restoration of your **local resources** (e.g., photos). It is recommended to use memos' built-in external resource libraries instead (Using local resources on a Cloud VM is not advisable.)

## Development and build

```shell
git clone https://github.com/hu3rror/memos-litestream.git
cd memos-litestream
# modify as necessary
docker buildx build ./ --file ./Dockerfile --tag <your-tag>
```

## Maintenance Status & Disclaimer

> ⚠️ **Project Status: Basic Maintenance Only (As-Is)**
>
> - **As-Is Provision**: This project is provided on an **"as-is"** basis with minimal or no ongoing maintenance. Use it at your own risk.
> - **No Upstream Guarantee**: If the official Memos upstream undergoes major refactoring, breaking changes, or architectural updates, **I will not follow up or push compatibility updates**.
> - **Data Safety**: You are solely responsible for your own data safety and backup integrity.
> - **Recommendation**: If you require the latest Memos features, long-term update support, or strict data security guarantees, please manage your own backups and **[migrate back to the official Memos image](#migrating-back-to-official-memos-image)**.

## Migrating Back to Official Memos Image

If you no longer need Litestream backup or Memogram integration, or if you want to switch directly to official upstream updates, you can easily migrate back to the official Memos image (`ghcr.io/usememos/memos`).

### Prerequisites & Important Notes

1. **Backup First**: Before making any changes, back up your local data directory (e.g., `~/.memos`).
2. **Litestream WAL Flush**: Stop the `memos-litestream` container cleanly to ensure all database transactions in the WAL file (`memos_prod.db-wal`) are fully checkpointed/flushed into `memos_prod.db`.
3. **Memogram Feature**: The official Memos container does **not** include the Memogram (Telegram bot) sidecar. If you rely on Telegram bot integration, you will need to host Memogram separately.
4. **File Permissions**: Official Memos runs as a non-root user (`nonroot`, UID 10001). If you encounter permission errors after migrating, adjust your folder ownership or set `-e MEMOS_UID=$(id -u) -e MEMOS_GID=$(id -g)`.

### Migration Steps

#### Step 1: Stop and remove the existing container
Stopping the container properly ensures Litestream flushes all pending WAL writes to `memos_prod.db`.

```shell
docker stop memos
docker rm memos
```

#### Step 2: Backup your local data
Make a copy of your host data directory:

```shell
cp -r ~/.memos ~/.memos_backup
```

#### Step 3: Launch the official Memos container
Run the official container using the exact same host volume path (`~/.memos`):

**Using `docker run`:**

```shell
docker run -d \
  --name memos \
  --restart unless-stopped \
  -p 5230:5230 \
  -v ~/.memos:/var/opt/memos \
  ghcr.io/usememos/memos:latest
```

**Using `docker-compose.yml`:**

```yaml
version: "3.0"
services:
  memos:
    image: ghcr.io/usememos/memos:latest
    container_name: memos
    restart: unless-stopped
    ports:
      - "5230:5230"
    volumes:
      - ~/.memos:/var/opt/memos
```

#### Step 4: Verify your instance
Open `http://localhost:5230` in your browser to confirm your data, account, and memos are intact.