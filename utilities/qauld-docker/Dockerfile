FROM rust:latest AS builder

RUN apt-get update && apt-get install -y protobuf-compiler libdbus-1-dev pkg-config

WORKDIR /qaul

# Monorepo layout expected by qaul-proto (`../../../protobuf/...` from `rust/qaul-proto/src`).
# Build from repository root, for example:
#   docker build -f utilities/qauld-docker/Dockerfile -t qauld-local:test .
COPY rust /qaul/rust
COPY protobuf /qaul/protobuf

WORKDIR /qaul/rust

RUN cargo build --release -p qauld


FROM debian:bookworm-slim AS runner

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /srv/qaul && chown 1000:1000 /srv/qaul

ENV GID=1000
ENV UID=1000
ENV PORT=9229
ENV NAME="Self-hosted Qaul"
# Must match rust/libqaul Cargo.toml version (used when seeding /srv/qaul/version with entrypoint).
ARG LIBQAUL_PKG_VERSION=2.0.0-rc.5
ENV LIBQAUL_PKG_VERSION=$LIBQAUL_PKG_VERSION

COPY --from=builder --chown=${UID}:${GID} /qaul/rust/target/release/qauld /usr/local/bin/qauld

COPY utilities/qauld-docker/config.default.yaml /etc/qaul/config.default.yaml
COPY utilities/qauld-docker/config.stock.yaml /etc/qaul/config.stock.yaml
COPY utilities/qauld-docker/config.dual.yaml /etc/qaul/config.dual.yaml
COPY utilities/qauld-docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh \
    && chown ${UID}:${GID} /etc/qaul/config.default.yaml \
       /etc/qaul/config.stock.yaml /etc/qaul/config.dual.yaml

EXPOSE 9229
USER ${UID}:${GID}

WORKDIR /srv/qaul

ENV RUST_BACKTRACE=1
# QAUL_CONFIG_PRESET selects /etc/qaul/config.{default,stock,dual}.yaml when seeding (see entrypoint.sh).
# Optional: QAUL_OVERWRITE_DEFAULT_CONFIG=1 replaces config on every start (destructive).
ENTRYPOINT ["/entrypoint.sh"]
