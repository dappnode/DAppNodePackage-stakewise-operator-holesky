#!/bin/sh

# TODO: Allow adding more than 1 keystore (upload compressed file and extract inside keystore dir)

set_execution_endpoint() {
    case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER in
    "goerli-geth.dnp.dappnode.eth")
        EXECUTION_ENDPOINTS="http://goerli-geth.dappnode:8551"
        ;;
    "goerli-nethermind.dnp.dappnode.eth")
        EXECUTION_ENDPOINTS="http://goerli-nethermind.dappnode:8551"
        ;;
    "goerli-besu.dnp.dappnode.eth")
        EXECUTION_ENDPOINTS="http://goerli-besu.dappnode:8551"
        ;;
    "goerli-erigon.dnp.dappnode.eth")
        EXECUTION_ENDPOINTS="http://goerli-erigon.dappnode:8551"
        ;;
    *)
        echo "Unknown value for _DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER: $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER"
        EXECUTION_ENDPOINTS=$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER
        ;;
    esac
}

set_beacon_node_endpoint() {
    case "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER" in
    "prysm-prater.dnp.dappnode.eth")
        export CONSENSUS_ENDPOINTS="http://beacon-chain.prysm-prater.dappnode:3500"
        ;;
    "teku-prater.dnp.dappnode.eth")
        export CONSENSUS_ENDPOINTS="http://beacon-chain.teku-prater.dappnode:3500"
        ;;
    "lighthouse-prater.dnp.dappnode.eth")
        export CONSENSUS_ENDPOINTS="http://beacon-chain.lighthouse-prater.dappnode:3500"
        ;;
    "nimbus-prater.dnp.dappnode.eth")
        export CONSENSUS_ENDPOINTS="http://beacon-validator.nimbus-prater.dappnode:4500"
        ;;
    "lodestar-prater.dnp.dappnode.eth")
        export CONSENSUS_ENDPOINTS="http://beacon-chain.lodestar-prater.dappnode:3500"
        ;;
    *)
        echo "Unknown value for _DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER: $_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER"
        export CONSENSUS_ENDPOINTS=$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER
        ;;
    esac
}

# Write keystore password to file
echo "$KEYSTORES_PASSWORD" >/data/keystores/password.txt

# Write hot wallet password to file
echo "$OPERATOR_WALLET_PASSWORD" >/data/operator/password.txt

exec py /src/main.py start --verbose false \
    --metrics-port 6000 \
    --metrics-host "*" \
    --network goerli \
    --deposit-data-file /data/deposit_data.json \
    --keystores-dir /data/keystores \
    --keystores-password-file /data/keystores/password.txt \
    --hot-wallet-file /data/operator/wallet.json \
    --hot-wallet-password-file /data/operator/password.txt \
    --vault $VAULT_CONTRACT_ADDRESS \
    --harvest-vault $HARVEST_VAULT
