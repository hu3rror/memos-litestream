ARG LITESTREAM_IMAGE_TAG=0.3.13
ARG MEMOS_IMAGE_TAG=0.22.0

# Build litestream
FROM docker.io/litestream/litestream:${LITESTREAM_IMAGE_TAG} AS litestream_package
ENTRYPOINT []

# Get official memos image and let it as a base
FROM ghcr.io/usememos/memos:${MEMOS_IMAGE_TAG} AS production
ENTRYPOINT []

# Set working directory
WORKDIR /usr/local/memos

# Copy litestream binary to /usr/local/bin
COPY --from=litestream_package /usr/local/bin/litestream /usr/local/bin/litestream

# Copy litestream configuration file to /etc/
COPY etc/litestream.yml /etc/litestream.yml

# Copy startup script and make it executable.
COPY scripts/run.sh /usr/local/memos/run.sh
RUN chmod +x /usr/local/memos/run.sh

# Copy Memogram environment file
ARG TARGETARCH
ARG USE_MEMOGRAM=0
ENV MEMOGRAM_TAG=0.1.1
RUN if [ "$USE_MEMOGRAM" = "1" ]; then \
        apk add --no-cache gcompat procps && \
        mkdir -p /usr/local/memos/telegram_bot && \
        wget https://github.com/usememos/telegram-integration/releases/download/v${MEMOGRAM_TAG}/memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
        tar -xvf memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
        mv memogram /usr/local/memos/telegram_bot/ && \
        rm memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz README.md && \
        chown root:root ./telegram_bot/memogram && \
        chmod +x ./telegram_bot/memogram && \
        COPY etc/memogram.env /usr/local/memos/telegram_bot/.env; \
    fi
# Define ENV
ENV DB_PATH="/var/opt/memos/memos_prod.db"
ENV MEMOS_PORT="5230"
EXPOSE $MEMOS_PORT

# Run memos with litestream (Default WORKDIR is `/usr/local/memos/`)
CMD ["./run.sh"]
