FROM europe-west4-docker.pkg.dev/stakewiselabs/public/v3-operator:master

RUN mkdir -p /data

# Install python3
RUN apk update && apk add python3

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]