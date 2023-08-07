#!/bin/sh

# TODO: Allow adding more than 1 keystore (upload compressed file and extract inside keystore dir)

get_execution_endpoint() {
    case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER in
    "goerli-geth.dnp.dappnode.eth")
        echo "http://goerli-geth.dappnode:8545"
        ;;
    "goerli-nethermind.dnp.dappnode.eth")
        echo "http://goerli-nethermind.dappnode:8545"
        ;;
    "goerli-besu.dnp.dappnode.eth")
        echo "http://goerli-besu.dappnode:8545"
        ;;
    "goerli-erigon.dnp.dappnode.eth")
        echo "http://goerli-erigon.dappnode:8545"
        ;;
    *)
        echo "$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER"
        ;;
    esac
}

get_beacon_node_endpoint() {
    case "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER" in
    "prysm-prater.dnp.dappnode.eth")
        echo "http://beacon-chain.prysm-prater.dappnode:3500"
        ;;
    "teku-prater.dnp.dappnode.eth")
        echo "http://beacon-chain.teku-prater.dappnode:3500"
        ;;
    "lighthouse-prater.dnp.dappnode.eth")
        echo "http://beacon-chain.lighthouse-prater.dappnode:3500"
        ;;
    "nimbus-prater.dnp.dappnode.eth")
        echo "http://beacon-validator.nimbus-prater.dappnode:4500"
        ;;
    "lodestar-prater.dnp.dappnode.eth")
        echo "http://beacon-chain.lodestar-prater.dappnode:3500"
        ;;
    *)
        echo "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER"
        ;;
    esac
}

# Write keystore password to file
echo "$KEYSTORES_PASSWORD" >/app/data/keystores/password.txt

# Write hot wallet password to file
echo "$OPERATOR_WALLET_PASSWORD" >/app/data/operator/password.txt

exec python3 /app/src/main.py start --network goerli \
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
