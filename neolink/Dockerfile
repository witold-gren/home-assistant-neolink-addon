ARG BUILD_FROM

# Build the Neolink fork from source: upstream Neolink at a fixed commit + the patches in patches/
# (WebSocket API, Reolink push notifications, battery-friendly RTSP). Same build environment as the
# official Neolink image.
FROM docker.io/rust:slim-bookworm AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git openssl libssl-dev ca-certificates pkg-config \
      libgstrtspserver-1.0-dev libgstreamer1.0-dev libgtk2.0-dev \
      protobuf-compiler libglib2.0-dev \
    && rm -rf /var/lib/apt/lists/*
ARG NEOLINK_REPO=https://github.com/QuantumEntangledAndy/neolink.git
ARG NEOLINK_COMMIT=6e05e7844b5b50f89787d30bffcbbd3471bfcfde
WORKDIR /src
RUN git init -q . && git remote add origin "${NEOLINK_REPO}" \
    && git fetch -q --depth 1 origin "${NEOLINK_COMMIT}" && git checkout -q FETCH_HEAD
COPY patches/ /patches/
RUN git -c user.name=build -c user.email=build@localhost am -q /patches/*.patch \
    && cargo build --release \
    && cp target/release/neolink /neolink

# Runtime: the official Neolink image (Debian bookworm with GStreamer).
FROM ${BUILD_FROM}

# jq: app options -> neolink.toml; curl: Supervisor API (discovery for the integration);
# tzdata: local time in the log (TZ comes from the Supervisor)
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq curl ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /neolink /usr/local/bin/neolink
COPY run.sh /run.sh
RUN chmod a+x /run.sh /usr/local/bin/neolink

ENTRYPOINT ["/run.sh"]
