ARG LITESTREAM_IMAGE_TAG=0.3.13
ARG MEMOS_IMAGE_TAG=0.22.2

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
COPY scripts/run.sh ./run.sh
RUN chmod +x ./run.sh

# Install memogram
ARG TARGETARCH
ARG USE_MEMOGRAM=0
ENV MEMOGRAM_TAG=0.1.4

RUN if [ "$USE_MEMOGRAM" = "1" ]; then \
    apk add --no-cache gcompat procps && \
    wget https://github.com/usememos/telegram-integration/releases/download/v${MEMOGRAM_TAG}/memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    tar -xvf memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    rm memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz README.md && \
    chmod +x ./memogram; \
    fi

# Define ENV
ENV MEMOS_PORT="5230"
ENV SERVER_ADDR=dns:localhost:${MEMOS_PORT}
ENV DB_PATH="/var/opt/memos/memos_prod.db"

# Expose port
EXPOSE ${MEMOS_PORT}

# Run memos with litestream (Default WORKDIR is `/usr/local/memos/`)
CMD ["./run.sh"]
