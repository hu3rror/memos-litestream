ARG LITESTREAM_IMAGE_TAG=0.3.13
ARG MEMOS_IMAGE_TAG=0.24.0

# Get litestream image
FROM docker.io/litestream/litestream:${LITESTREAM_IMAGE_TAG} AS litestream_package
ENTRYPOINT []

# Get official memos image
FROM ghcr.io/usememos/memos:${MEMOS_IMAGE_TAG} AS memos_package
ENTRYPOINT []

# Build production image 
FROM alpine:latest AS production

# Set working directory
WORKDIR /usr/local/memos

# Copy binary to /usr/local/bin
COPY --from=litestream_package /usr/local/bin/litestream /usr/local/bin/litestream
COPY --from=memos_package /usr/local/memos/memos /usr/local/memos/

# Set timezone
RUN apk add --no-cache tzdata

# Create /var/opt/memos
RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos

# Copy litestream configuration file to /etc/
COPY etc/litestream.yml /etc/litestream.yml

# Copy startup script and make it executable.
COPY scripts/run.sh ./run.sh
RUN chmod +x ./run.sh

# Install memogram
ARG TARGETARCH
ARG USE_MEMOGRAM=0
ENV MEMOGRAM_TAG=0.2.1

RUN if [ "$USE_MEMOGRAM" = "1" ]; then \
    apk add --no-cache gcompat procps && \
    wget https://github.com/usememos/telegram-integration/releases/download/v${MEMOGRAM_TAG}/memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    tar -xvf memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz && \
    rm memogram_v${MEMOGRAM_TAG}_linux_${TARGETARCH}.tar.gz README.md && \
    chmod +x ./memogram; \
    fi

# Define ENV
ENV TZ="UTC"
ENV MEMOS_PORT="5230"
ENV MEMOS_MODE="prod"
ENV SERVER_ADDR=dns:localhost:${MEMOS_PORT}
ENV DB_PATH="/var/opt/memos/memos_prod.db"

# Expose port
EXPOSE ${MEMOS_PORT}

# Run memos with litestream (Default WORKDIR is `/usr/local/memos/`)
CMD ["./run.sh"]
