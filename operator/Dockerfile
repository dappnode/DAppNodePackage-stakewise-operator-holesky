ARG UPSTREAM_VERSION

FROM stakewiselabs/v3-operator:${UPSTREAM_VERSION}

RUN mkdir -p /app/data

ENV NETWORK=holesky \
    DATA_DIR=/app/data/stakewise \
    MNEMONIC_DIR=/app/data/mnemonic \
    CONFIG_DIR=/app/data/config \
    DATABASE_DIR=/app/data/database

USER root

RUN apt update && apt upgrade -y && apt install -y curl jq

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]