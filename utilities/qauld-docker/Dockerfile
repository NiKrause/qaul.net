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

COPY --from=builder --chown=${UID}:${GID} /qaul/rust/target/release/qauld /usr/local/bin/qauld

EXPOSE 9229
USER ${UID}:${GID}

WORKDIR /srv/qaul

ENV RUST_BACKTRACE=1
ENTRYPOINT ["/bin/sh", "-c", "exec /usr/local/bin/qauld --name \"$NAME\" --port \"$PORT\""]
