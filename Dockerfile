ARG LITESTREAM_IMAGE_TAG=0.3.13
ARG MEMOS_IMAGE_TAG=0.22.0

# Build litestream
FROM docker.io/litestream/litestream:${LITESTREAM_IMAGE_TAG} AS package
ENTRYPOINT []

# Build memos
FROM ghcr.io/usememos/memos:${MEMOS_IMAGE_TAG} AS production
ENTRYPOINT []

# Copy litestream to /usr/local/bin
COPY --from=package /usr/local/bin/litestream /usr/local/bin/litestream

# Copy litestream global configuration file
COPY etc/litestream.yml /etc/litestream.yml

# Copy startup script and make it executable.
COPY scripts/run-memos-with-litestream.sh /usr/local/memos/run-memos-with-litestream.sh
RUN chmod +x /usr/local/memos/run-memos-with-litestream.sh

# Define ENV
ENV DB_PATH="/var/opt/memos/memos_prod.db"

# Run memos with litestream (Default WORKDIR is `/usr/local/memos/`)
CMD ["./run-memos-with-litestream.sh"]
