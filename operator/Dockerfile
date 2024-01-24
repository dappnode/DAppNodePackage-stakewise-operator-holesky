ARG UPSTREAM_VERSION

FROM europe-west4-docker.pkg.dev/stakewiselabs/public/v3-operator:${UPSTREAM_VERSION}

RUN mkdir -p /app/data/keystores /app/data/operator /app/data/stakewise

ENV NETWORK=holesky

USER root

# Install python3
RUN apt-get update && apt-get install python3 -y

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]