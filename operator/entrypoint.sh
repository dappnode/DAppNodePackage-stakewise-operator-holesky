#!/bin/bash

to_lower_case() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_upper_case() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

operator() {
    python3 /app/src/main.py "$@"
}

load_envs() {
    NETWORK=$(to_lower_case "$NETWORK")
    UPPER_CASE_NETWORK=$(to_upper_case "$NETWORK")

    VALIDATORS_NUMBER_PATH="$DATA_DIR/validators_number.txt"
    MNEMONIC_PATH="$MNEMONIC_DIR/mnemonic.txt"
    VAULT_CONTRACT_ADDRESS_PATH="$DATA_DIR/vault_contract_address.txt"

    load_env_and_store_to_file "VAULT_CONTRACT_ADDRESS" "$VAULT_CONTRACT_ADDRESS_PATH"
    load_env_and_store_to_file "VALIDATORS_NUMBER" "$VALIDATORS_NUMBER_PATH"

    VAULT_CONTRACT_ADDRESS=$(to_lower_case "$VAULT_CONTRACT_ADDRESS")

    VAULT_DATA_DIR="$DATA_DIR/$VAULT_CONTRACT_ADDRESS"
    KEYSTORES_DIR="$VAULT_DATA_DIR/keystores"
    DEPOSIT_DATA_FILE_PATH="$VAULT_DATA_DIR/deposit_data.json"
    CONFIG_FILE_PATH="$VAULT_DATA_DIR/config.json"
    WALLET_FILE_PATH="$VAULT_DATA_DIR/wallet/wallet.json"
}

load_env_and_store_to_file() {
    local var_name="$1"
    local file_path="$2"

    if [ -n "${!var_name}" ]; then
        echo "${!var_name}" >"$file_path"
    else
        if [ -f "$file_path" ]; then
            read -r value <"$file_path"
            declare -g "$var_name"=$(to_lower_case "$value")
        fi
    fi

    if [ -z "${!var_name}" ]; then
        echo "[ERROR] $var_name is not set. Please set it in the config and click update or upload a backup."
        echo "[INFO] Waiting 5 minutes before exiting..."
        sleep 300
        exit 0
    fi

    echo "[INFO] Loaded variable $var_name: ${!var_name}"
}

create_directories() {
    mkdir -p $DATA_DIR $MNEMONIC_DIR $DATABASE_DIR $VAULT_DATA_DIR
}

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

init_operator() {

    if [ -f "$CONFIG_FILE_PATH" ]; then
        echo "[INFO] Operator for $VAULT_CONTRACT_ADDRESS already initialized."
    else
        echo "[INFO] Initializing operator for $VAULT_CONTRACT_ADDRESS..."
        # This command creates the config.json file and the mnemonic
        MNEMONIC=$(operator init --network "$NETWORK" --vault "$VAULT_CONTRACT_ADDRESS" --data-dir "$DATA_DIR" --language english --no-verify)

        echo "$MNEMONIC" >"$MNEMONIC_PATH"
    fi

    # This is the mnemonic for both the keystore and the wallet
    MNEMONIC=$(cat "$MNEMONIC_PATH")
}

create_wallet() {
    if [ -f "$WALLET_FILE_PATH" ]; then
        echo "[INFO] Operator wallet for $VAULT_CONTRACT_ADDRESS already created."
    else
        echo "[INFO] Creating operator wallet for $VAULT_CONTRACT_ADDRESS..."
        operator create-wallet --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$DATA_DIR"
    fi
}

create_validators() {
    # Get the number of files inside the keystores directory that follow the pattern "keystore-*.json"
    KEY_FILES_COUNT=$(ls -1 $KEYSTORES_DIR/keystore-*.json 2>/dev/null | wc -l)

    # Check if the number of files is equal to the number of validators
    if [ $KEY_FILES_COUNT -eq $VALIDATORS_NUMBER ]; then
        echo "[INFO] The number of validator keys matches the defined number of validators: $VALIDATORS_NUMBER."

    elif [ ! -f "$MNEMONIC_PATH" ]; then
        echo "[ERROR] Mnemonic file not found at $MNEMONIC_PATH. Validator keys cannot be created. Upload the backup with the mnemonic file."

    else
        echo "[INFO] The number of validator keys ($KEY_FILES_COUNT) does not match the defined number of validators: $VALIDATORS_NUMBER."

        VALIDATORS_TO_CREATE=$(($VALIDATORS_NUMBER - $KEY_FILES_COUNT))

        if [ $VALIDATORS_TO_CREATE -lt 0 ]; then
            echo "[ERROR] It is not possible to remove existing keystores"

        elif [ $KEY_FILES_COUNT -eq 0 ]; then
            echo "[INFO] Creating validator keys for $VAULT_CONTRACT_ADDRESS..."
            operator create-keys --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$DATA_DIR" --count $VALIDATORS_TO_CREATE

        else
            echo "[INFO] Creating $VALIDATORS_TO_CREATE validator keys..."
            mv $VAULT_DATA_DIR/deposit_data.json $VAULT_DATA_DIR/deposit_data_old.json

            operator create-keys --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$DATA_DIR" --count $VALIDATORS_TO_CREATE
            mv $VAULT_DATA_DIR/deposit_data.json $VAULT_DATA_DIR/deposit_data_new.json

            operator merge-deposit-data -d "$VAULT_DATA_DIR/deposit_data_old.json" -d "$VAULT_DATA_DIR/deposit_data_new.json" -m "$VAULT_DATA_DIR/deposit_data.json"
        fi

    fi
}

post_wallet_address_to_dappmanager() {
    # Read JSON from PRIVATE_KEY_FILE and extract the publicKey
    WALLET_ADDRESS=$(jq -r '.address' ${WALLET_FILE_PATH})

    # Post ENR to dappmanager
    curl --connect-timeout 5 \
        --max-time 10 \
        --silent \
        --retry 5 \
        --retry-delay 0 \
        --retry-max-time 40 \
        -X POST "http://dappmanager.dappnode/data-send?key=Hot%20Wallet%20Address&data=${WALLET_ADDRESS}" ||
        {
            echo -e "[ERROR] failed to post hot wallet address to dappmanager\n"
        }
}

start_operator() {
    echo "[INFO] Starting operator for $VAULT_CONTRACT_ADDRESS..."

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
        --data-dir $DATA_DIR \
        --database-dir $DATABASE_DIR
}

main() {
    load_envs
    create_directories
    init_operator
    create_wallet
    create_validators
    post_wallet_address_to_dappmanager
    start_operator
}

main
