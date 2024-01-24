#!/bin/sh

# TODO: Allow adding more than 1 keystore (upload compressed file and extract inside keystore dir)

# NETWORK to upper case
UPPER_CASE_NETWORK=$(echo "$NETWORK" | tr '[:lower:]' '[:upper:]')

get_execution_endpoint() {
    case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_${UPPER_CASE_NETWORK} in
    "${NETWORK}-geth.dnp.dappnode.eth")
        echo "http://${NETWORK}-geth.dappnode:8545"
        ;;
    "${NETWORK}-nethermind.dnp.dappnode.eth")
        echo "http://${NETWORK}-nethermind.dappnode:8545"
        ;;
    "${NETWORK}-besu.dnp.dappnode.eth")
        echo "http://${NETWORK}-besu.dappnode:8545"
        ;;
    "${NETWORK}-erigon.dnp.dappnode.eth")
        echo "http://${NETWORK}-erigon.dappnode:8545"
        ;;
    *)
        echo "$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_${UPPER_CASE_NETWORK}"
        ;;
    esac
}

get_beacon_node_endpoint() {
    case "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_${UPPER_CASE_NETWORK}" in
    "prysm-${NETWORK}.dnp.dappnode.eth")
        echo "http://beacon-chain.prysm-${NETWORK}.dappnode:3500"
        ;;
    "teku-${NETWORK}.dnp.dappnode.eth")
        echo "http://beacon-chain.teku-${NETWORK}.dappnode:3500"
        ;;
    "lighthouse-${NETWORK}.dnp.dappnode.eth")
        echo "http://beacon-chain.lighthouse-${NETWORK}.dappnode:3500"
        ;;
    "nimbus-${NETWORK}.dnp.dappnode.eth")
        echo "http://beacon-validator.nimbus-${NETWORK}.dappnode:4500"
        ;;
    "lodestar-${NETWORK}.dnp.dappnode.eth")
        echo "http://beacon-chain.lodestar-${NETWORK}.dappnode:3500"
        ;;
    *)
        echo "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_${UPPER_CASE_NETWORK}"
        ;;
    esac
}

# Write keystore password to file
echo "$KEYSTORES_PASSWORD" >/app/data/keystores/password.txt

# Write hot wallet password to file
echo "$OPERATOR_WALLET_PASSWORD" >/app/data/operator/password.txt

exec python3 /app/src/main.py start --network ${NETWORK} \
    --deposit-data-file /app/data/deposit_data.json \
    --keystores-dir /app/data/keystores \
    --keystores-password-file /app/data/keystores/password.txt \
    --hot-wallet-file /app/data/operator/wallet.json \
    --hot-wallet-password-file /app/data/operator/password.txt \
    --vault $VAULT_CONTRACT_ADDRESS \
    --execution-endpoints $(get_execution_endpoint) \
    --consensus-endpoints $(get_beacon_node_endpoint) \
    --data-dir /app/data/stakewise \
    --metrics-port 8008 \
    --metrics-host 0.0.0.0 \
    --verbose
