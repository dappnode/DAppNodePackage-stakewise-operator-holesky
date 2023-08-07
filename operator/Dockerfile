ARG UPSTREAM_VERSION

FROM europe-west4-docker.pkg.dev/stakewiselabs/public/v3-operator:${UPSTREAM_VERSION}

RUN mkdir -p /app/data/keystores /app/data/operator /app/data/stakewise

# Install python3
RUN apk update && apk add python3

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]