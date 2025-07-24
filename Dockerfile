ARG LITESTREAM_IMAGE_TAG=0.3.13
ARG MEMOS_IMAGE_TAG=0.25.0

# Get litestream image
FROM docker.io/litestream/litestream:${LITESTREAM_IMAGE_TAG} AS litestream_package
ENTRYPOINT []

# Get official memos image
FROM ghcr.io/usememos/memos:${MEMOS_IMAGE_TAG} AS memos_package
ENTRYPOINT []

# Build production image 
FROM alpine:3.21 AS production

# Install supervisor and tini for process management
RUN apk add --no-cache supervisor tzdata procps

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

# Copy supervisor configuration files
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/memos_service.conf /etc/supervisord/conf.d/memos_service.conf
COPY etc/memogram_service.conf /usr/local/memos/memogram_service.conf

# Copy startup script
COPY scripts/run.sh /usr/local/memos/run.sh
COPY scripts/start_memos_service.sh /usr/local/memos/start_memos_service.sh
COPY scripts/start_memogram_service.sh /usr/local/memos/start_memogram_service.sh

# Make scripts executable
RUN chmod +x /usr/local/memos/run.sh \
    && chmod +x /usr/local/memos/start_memos_service.sh \
    && chmod +x /usr/local/memos/start_memogram_service.sh

# Install memogram
ARG TARGETARCH
ARG USE_MEMOGRAM=0
ENV MEMOGRAM_TAG=0.3.0

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

# run.sh will do initial setup, then tini will launch supervisord
ENTRYPOINT ["/usr/local/memos/run.sh"]
# CMD will be passed to supervisord
# -n: do not daemonize;
# -c: specify the config file
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]