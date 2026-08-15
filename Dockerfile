ARG MEMOS_IMAGE_TAG=0.30.0
ARG LITESTREAM_IMAGE_TAG=0.5.15

# Get litestream image
FROM docker.io/litestream/litestream:${LITESTREAM_IMAGE_TAG} AS litestream_package
ENTRYPOINT []

# Get official memos image
FROM ghcr.io/usememos/memos:${MEMOS_IMAGE_TAG} AS memos_package
ENTRYPOINT []

# Build production image 
FROM alpine:3.24.1 AS production

# Install runtime dependencies
RUN apk add --no-cache tzdata procps

# Set working directory
WORKDIR /usr/local/memos

# Copy binary to /usr/local/bin
COPY --from=litestream_package /usr/local/bin/litestream /usr/local/bin/litestream
COPY --from=memos_package /usr/local/memos/memos /usr/local/memos/

# Create /var/opt/memos
RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos

# Copy litestream configuration file
COPY etc/litestream.yml /etc/litestream.yml

# Copy startup scripts
COPY scripts/entrypoint.sh /usr/local/memos/entrypoint.sh
RUN chmod +x /usr/local/memos/entrypoint.sh

# Install memogram
ARG TARGETARCH
ARG USE_MEMOGRAM=0
ENV MEMOGRAM_TAG=0.5.0

RUN if [ "$USE_MEMOGRAM" = "1" ]; then \
    apk add --no-cache gcompat procps wget && \
    wget https://github.com/usememos/telegram-integration/releases/download/v${MEMOGRAM_TAG}/memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    tar -xvf memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz -C /usr/local/memos && \
    rm memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    chmod +x /usr/local/memos/memogram; \
    fi

# Define ENV
ENV TZ="UTC"
ENV MEMOS_PORT="5230"
ENV MEMOS_MODE="prod"
ENV SERVER_ADDR=dns:localhost:${MEMOS_PORT}
ENV DB_PATH="/var/opt/memos/memos_prod.db"
ENV ALLOWED_USERNAMES=""

# Expose port
EXPOSE ${MEMOS_PORT}

# entrypoint.sh handles all startup orchestration
ENTRYPOINT ["/usr/local/memos/entrypoint.sh"]
