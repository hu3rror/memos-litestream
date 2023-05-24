FROM docker.io/alpine:3.18 AS builder

# Install required component
RUN apk add --no-cache unzip wget

# Define arch (use `--build-arg` to define, options: `arm64`, `amd64` )
ARG ARCH=amd64

# Define apps version
ARG MEMOS_VERSION=0.13.0
ARG LITESTREAM_VERSION=v0.3.9

# Get memos binary
RUN wget -q -O /tmp/memos.zip https://nightly.link/usememos/memos/workflows/build-artifacts/release%2F${MEMOS_VERSION}/memos-binary-ubuntu-latest-${ARCH}.zip && \
    unzip /tmp/memos.zip && \
    mv "memos--${ARCH}" /usr/local/bin/memos && \
    chmod +x /usr/local/bin/memos

# Get litestream binary
RUN wget -q -O /tmp/litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/$LITESTREAM_VERSION/litestream-${LITESTREAM_VERSION}-linux-${ARCH}-static.tar.gz && \
    tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz && \
    rm -rf litestream.tar.gz && \
    chmod +x /usr/local/bin/litestream

FROM docker.io/ubuntu:22.04 AS monolithic

# Install essential packages
RUN apt-get update && \
    apt-get install -yq --no-install-recommends tzdata ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy binary from builder.
COPY --from=builder /usr/local/bin/memos /usr/local/bin/memos
COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream

# Set timezone
ENV TZ="UTC"

# Directory to store the data, which can be referenced as the mounting point.
RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos

# Expose port
EXPOSE 5230

# Copy litestream configuration file
COPY etc/litestream.yml /etc/litestream.yml

# Copy startup script and make it executable.
COPY scripts/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Run memos with litestream
CMD ["run.sh"]
