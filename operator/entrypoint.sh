#!/bin/sh

VAULT_DATA_DIR="$DATA_DIR/$VAULT_CONTRACT_ADDRESS"
MNEMONIC_PATH="$VAULT_DATA_DIR/mnemonic.txt"

# Ensure NETWORK is lowercase
NETWORK=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')

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

if [ -z "$VAULT_CONTRACT_ADDRESS" ]; then
    echo "[ERROR] VAULT_CONTRACT_ADDRESS is not set. Please set it in the config."
    exit 0
fi

if [ -z $VALIDATORS_NUMBER ]; then
    echo "[ERROR] VALIDATORS_NUMBER is not set. Please set it in the config."
    exit 0
fi

if [ ! -d "$VAULT_DATA_DIR" ]; then
    echo "[INFO] Initializing operator for $VAULT_CONTRACT_ADDRESS..."
    MNEMONIC=$(python3 /app/src/main.py init --network $NETWORK --vault $VAULT_CONTRACT_ADDRESS --data-dir $DATA_DIR --language english --no-verify)
    echo "$MNEMONIC" >$MNEMONIC_PATH
else
    echo "[INFO] Operator for $VAULT_CONTRACT_ADDRESS already initialized."
fi

if [ ! -f "$VAULT_DATA_DIR/wallet/wallet.json" ]; then
    echo "[INFO] Creating operator wallet for $VAULT_CONTRACT_ADDRESS..."
    python3 /app/src/main.py create-wallet --vault $VAULT_CONTRACT_ADDRESS --mnemonic $MNEMONIC_PATH --data-dir $DATA_DIR
else
    echo "[INFO] Operator wallet for $VAULT_CONTRACT_ADDRESS already created."
fi

if [ ! "$(ls -A $VAULT_DATA_DIR/keystores)" ]; then
    echo "[INFO] Creating validator keys for $VAULT_CONTRACT_ADDRESS..."
    python3 /app/src/main.py create-keys --vault $VAULT_CONTRACT_ADDRESS --mnemonic $MNEMONIC_PATH --data-dir $DATA_DIR --count $VALIDATORS_NUMBER
else
    echo "[INFO] Validator keys for $VAULT_CONTRACT_ADDRESS already created."
fi

exec python3 /app/src/main.py start \
    --log-level $LOG_LEVEL \
    --log-format plain \
    --vault $VAULT_CONTRACT_ADDRESS \
    --execution-endpoints $(get_execution_endpoint) \
    --consensus-endpoints $(get_beacon_node_endpoint) \
    --enable-metrics \
    --metrics-port 8008 \
    --metrics-host 0.0.0.0 \
    --network $NETWORK \
    --data-dir $DATA_DIR
