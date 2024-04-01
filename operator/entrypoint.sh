#!/bin/sh

set -eu pipefail

# Ensure NETWORK and VAULT_CONTRACT_ADDRESS are lowercase
NETWORK=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
VAULT_CONTRACT_ADDRESS=$(echo "$VAULT_CONTRACT_ADDRESS" | tr '[:upper:]' '[:lower:]')

UPPER_CASE_NETWORK=$(echo "$NETWORK" | tr '[:lower:]' '[:upper:]')

VALIDATORS_NUMBER_PATH="$DATA_DIR/validators_number.txt"
MNEMONIC_PATH="$MNEMONIC_DIR/mnemonic.txt"
VAULT_CONTRACT_ADDRESS_PATH="$DATA_DIR/vault_contract_address.txt"

if [ -n "$VAULT_CONTRACT_ADDRESS" ]; then
    echo "$VAULT_CONTRACT_ADDRESS" >$VAULT_CONTRACT_ADDRESS_PATH
else
    VAULT_CONTRACT_ADDRESS=$(cat $VAULT_CONTRACT_ADDRESS_PATH | tr '[:upper:]' '[:lower:]')
fi

if [ -z "$VAULT_CONTRACT_ADDRESS" ]; then
    echo "[ERROR] VAULT_CONTRACT_ADDRESS is not set. Please set it in the config and click update."
    exit 0
fi

echo "[INFO] Loading operator with vault contract address: $VAULT_CONTRACT_ADDRESS..."

if [ -n "$VALIDATORS_NUMBER" ]; then
    echo "$VALIDATORS_NUMBER" >$VALIDATORS_NUMBER_PATH
else
    VALIDATORS_NUMBER=$(cat $VALIDATORS_NUMBER_PATH)
fi

if [ -z $VALIDATORS_NUMBER ]; then
    echo "[ERROR] VALIDATORS_NUMBER is not set. Please set it in the config and click update."
    exit 0
fi

echo "[INFO] Loading operator for $VALIDATORS_NUMBER validators..."

VAULT_DATA_DIR="$DATA_DIR/$VAULT_CONTRACT_ADDRESS"

echo "[INFO] Loaded variables: VAULT_CONTRACT_ADDRESS=$VAULT_CONTRACT_ADDRESS, VALIDATORS_NUMBER=$VALIDATORS_NUMBER, VAULT_DATA_DIR=$VAULT_DATA_DIR"

get_execution_endpoint() {
    execution_client_var_name="_DAPPNODE_GLOBAL_EXECUTION_CLIENT_${UPPER_CASE_NETWORK}"

    # Use eval to dynamically get the variable's value
    execution_client=$(eval echo \$$execution_client_var_name)

    case $execution_client in
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
        echo "$execution_client"
        ;;
    esac
}

get_beacon_node_endpoint() {
    consensus_client_var_name="_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_${UPPER_CASE_NETWORK}"

    # Use eval to dynamically get the variable's value
    consensus_client=$(eval echo \$$consensus_client_var_name)

    case $consensus_client in
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
        echo "$consensus_client"
        ;;
    esac
}

if [ -d "$VAULT_DATA_DIR" ]; then
    echo "[INFO] Operator for $VAULT_CONTRACT_ADDRESS already initialized."
else
    echo "[INFO] Initializing operator for $VAULT_CONTRACT_ADDRESS..."
    MNEMONIC=$(python3 /app/src/main.py init --network $NETWORK --vault $VAULT_CONTRACT_ADDRESS --data-dir $DATA_DIR --language english --no-verify)
    echo "$MNEMONIC" >$MNEMONIC_PATH
fi

MNEMONIC=$(cat $MNEMONIC_PATH)

if [ -f "$VAULT_DATA_DIR/wallet/wallet.json" ]; then
    echo "[INFO] Operator wallet for $VAULT_CONTRACT_ADDRESS already created."
else
    echo "[INFO] Creating operator wallet for $VAULT_CONTRACT_ADDRESS..."
    python3 /app/src/main.py create-wallet --vault $VAULT_CONTRACT_ADDRESS --mnemonic "$MNEMONIC" --data-dir $DATA_DIR
fi

if [ "$(ls -A $VAULT_DATA_DIR/keystores)" ]; then
    echo "[INFO] Validator keys for $VAULT_CONTRACT_ADDRESS already created."
else
    echo "[INFO] Creating validator keys for $VAULT_CONTRACT_ADDRESS..."
    python3 /app/src/main.py create-keys --vault $VAULT_CONTRACT_ADDRESS --mnemonic "$MNEMONIC" --data-dir $DATA_DIR --count $VALIDATORS_NUMBER
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
