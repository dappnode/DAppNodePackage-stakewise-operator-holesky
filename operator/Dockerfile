ARG UPSTREAM_VERSION

FROM stakewiselabs/v3-operator:${UPSTREAM_VERSION}

ARG STAKER_SCRIPTS_VERSION
ARG NETWORK
ARG DATA_DIR

ENV DATA_DIR=${DATA_DIR} \
    STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION}

USER root

RUN apt-get update && apt-get install -y curl jq

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ADD ${STAKER_SCRIPTS_URL}/dvt_lsd_tools.sh /etc/profile.d/

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/dvt_lsd_tools.sh

ENV NETWORK=${NETWORK}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]