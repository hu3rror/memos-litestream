ARG LITESTREAM_IMAGE_TAG=0.3.9
ARG MEMOS_IMAGE_TAG=0.18.0

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
COPY scripts/run.sh /usr/local/memos/run.sh
RUN chmod +x /usr/local/memos/run.sh

# Define ENV
ENV DB_PATH="/var/opt/memos/memos_prod.db"

# Run memos with litestream
CMD ["./run.sh"]
