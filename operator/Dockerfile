ARG UPSTREAM_VERSION

FROM stakewiselabs/v3-operator:${UPSTREAM_VERSION}

RUN mkdir -p /app/data

ENV NETWORK=holesky DATA_DIR=/app/data

USER root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]