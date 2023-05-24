ARG ALPINE_TAG=3.18
ARG UBUNTU_TAG=22.04

FROM docker.io/alpine:${ALPINE_TAG} AS builder

# Install required component
RUN apk add --no-cache unzip wget

# Define apps version
ARG MEMOS_VERSION=0.13.0
ARG LITESTREAM_VERSION=v0.3.9

# Define architecture component
ARG TARGETARCH

# Get memos binary
RUN wget -q -O /tmp/memos.zip https://nightly.link/usememos/memos/workflows/build-artifacts/release%2F${MEMOS_VERSION}/memos-binary-ubuntu-latest-${TARGETARCH}.zip \
    && unzip /tmp/memos.zip \
    && mv "memos--${TARGETARCH}" /usr/local/bin/memos \
    && chmod a+x /usr/local/bin/memos

# Get litestream binary
RUN wget -q -O /tmp/litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/$LITESTREAM_VERSION/litestream-${LITESTREAM_VERSION}-linux-${TARGETARCH}-static.tar.gz \
    && tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz \
    && rm -rf litestream.tar.gz \
    && chmod a+x /usr/local/bin/litestream

FROM docker.io/ubuntu:${UBUNTU_TAG} AS monolithic

# Install essential packages
RUN apt-get update \
    && apt-get install -yq --no-install-recommends tzdata ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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
RUN chmod a+x /usr/local/bin/run.sh

# Run memos with litestream
CMD ["run.sh"]
