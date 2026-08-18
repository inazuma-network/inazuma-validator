# Inazuma node — works identically on Linux, macOS, Windows, ARM and x86.
FROM rust:1.83-slim AS build
ARG INAZ_REPO=https://github.com/inazuma-network/inazuma-core.git
ARG INAZ_REF=main
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential pkg-config git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch ${INAZ_REF} ${INAZ_REPO} . && cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/target/release/inazuma /usr/local/bin/inazuma
COPY --from=build /src/genesis.json /etc/inazuma/genesis.json
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENV INAZ_PEERS=rpc.inazuma.network:9944 INAZ_ROLE=validator
VOLUME ["/var/lib/inazuma"]
EXPOSE 9944 9933
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
