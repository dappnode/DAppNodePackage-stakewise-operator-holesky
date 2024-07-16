ARG UPSTREAM_VERSION

FROM stakewiselabs/v3-operator:${UPSTREAM_VERSION}

ENV NETWORK=holesky \
    DATA_DIR=/app/data

USER root

RUN apt-get update && apt-get install -y curl jq

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]