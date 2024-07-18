#!/bin/bash

# shellcheck disable=SC1091 # Path is relative to the Dockerfile
. /etc/profile.d/dvt_lsd_tools.sh

operator() {
    python3 /app/src/main.py "$@"
}

load_envs() {
    DATABASE_DIR=${DATA_DIR}/database
    CONFIG_DIR=${DATA_DIR}/config
    STAKEWISE_DIR=${CONFIG_DIR}/stakewise
    MNEMONIC_DIR=${CONFIG_DIR}/mnemonic

    VALIDATORS_NUMBER_PATH="$STAKEWISE_DIR/validators_number.txt"
    MNEMONIC_PATH="$MNEMONIC_DIR/mnemonic.txt"
    VAULT_CONTRACT_ADDRESS_PATH="$STAKEWISE_DIR/vault_contract_address.txt"

    load_env_and_store_to_file "VAULT_CONTRACT_ADDRESS" "$VAULT_CONTRACT_ADDRESS_PATH"
    load_env_and_store_to_file "VALIDATORS_NUMBER" "$VALIDATORS_NUMBER_PATH"

    SUPPORTED_NETWORKS="mainnet holesky"
    NETWORK=$(to_lower_case "$NETWORK")
    VAULT_CONTRACT_ADDRESS=$(to_lower_case "$VAULT_CONTRACT_ADDRESS")

    VAULT_DATA_DIR="$STAKEWISE_DIR/$VAULT_CONTRACT_ADDRESS"
    KEYSTORES_DIR="$VAULT_DATA_DIR/keystores"
    CONFIG_FILE_PATH="$VAULT_DATA_DIR/config.json"
    WALLET_FILE_PATH="$VAULT_DATA_DIR/wallet/wallet.json"

    EXECUTION_RPC_API_URL=$(get_execution_rpc_api_url_from_global_env "$NETWORK" "$SUPPORTED_NETWORKS")
    BEACON_API_URL=$(get_beacon_api_url_from_global_env "$NETWORK" "$SUPPORTED_NETWORKS")
    BRAIN_URL=$(get_brain_api_url"$NETWORK" "$SUPPORTED_NETWORKS")
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
    mkdir -p "$STAKEWISE_DIR" "$MNEMONIC_DIR" "$DATABASE_DIR" "$VAULT_DATA_DIR"
}

init_operator() {

    if [ -f "$CONFIG_FILE_PATH" ]; then
        echo "[INFO] Operator for $VAULT_CONTRACT_ADDRESS already initialized."
    else

        if [ -d "$VAULT_DATA_DIR" ] && [ ! "$(ls -A $VAULT_DATA_DIR)" ]; then
            echo "[INFO] Removing empty directory $VAULT_DATA_DIR"
            rm -r "$VAULT_DATA_DIR"
        fi

        echo "[INFO] Initializing operator for $VAULT_CONTRACT_ADDRESS..."
        # This command creates the config.json file and the mnemonic
        MNEMONIC=$(operator init --network "$NETWORK" --vault "$VAULT_CONTRACT_ADDRESS" --data-dir "$STAKEWISE_DIR" --language english --no-verify)

        echo "$MNEMONIC" >"$MNEMONIC_PATH"
    fi

    # This is the mnemonic for both the keystore and the wallet
    MNEMONIC=$(cat "$MNEMONIC_PATH")
}

create_wallet() {
    if [ -f "$WALLET_FILE_PATH" ]; then
        echo "[INFO] Operator wallet for $VAULT_CONTRACT_ADDRESS already created."
        return
    fi

    echo "[INFO] Creating operator wallet for $VAULT_CONTRACT_ADDRESS..."
    operator create-wallet --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$STAKEWISE_DIR"
}

ensure_number_of_validators() {
    local key_files_count

    # Get the number of files inside the keystores directory that follow the pattern "keystore-*.json"
    key_files_count=$(ls -1 $KEYSTORES_DIR/keystore-*.json 2>/dev/null | wc -l)

    # Check if the number of files is equal to the number of validators
    if [ $key_files_count -eq $VALIDATORS_NUMBER ]; then
        echo "[INFO] The number of validator keys matches the defined number of validators: $VALIDATORS_NUMBER."
        return
    fi

    if [ ! -f "$MNEMONIC_PATH" ]; then
        echo "[ERROR] Mnemonic file not found at $MNEMONIC_PATH. Validator keys cannot be created. Upload the backup with the mnemonic file."
        return
    fi

    echo "[INFO] The number of validator keys ($key_files_count) does not match the defined number of validators: $VALIDATORS_NUMBER."
    _create_validators "$key_files_count"
}

_create_validators() {
    local key_files_count=$1
    local validators_to_create=$(($VALIDATORS_NUMBER - $key_files_count))

    if [ $validators_to_create -lt 0 ]; then
        # TODO: Allow it?
        echo "[ERROR] It is not possible to remove existing keystores"
        return 1
    fi

    if [ $key_files_count -eq 0 ]; then
        echo "[INFO] Creating validator keys for $VAULT_CONTRACT_ADDRESS..."
        operator create-keys --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$STAKEWISE_DIR" --count $validators_to_create
        return 0
    fi

    echo "[INFO] Creating $validators_to_create validator keys..."
    mv -f "${VAULT_DATA_DIR}/deposit_data.json" "${VAULT_DATA_DIR}/deposit_data_old.json"

    operator create-keys --vault "$VAULT_CONTRACT_ADDRESS" --mnemonic "$MNEMONIC" --data-dir "$STAKEWISE_DIR" --count $validators_to_create
    mv -f "${VAULT_DATA_DIR}/deposit_data.json" "${VAULT_DATA_DIR}/deposit_data_new.json"

    operator merge-deposit-data -d "$VAULT_DATA_DIR/deposit_data_old.json" -d "$VAULT_DATA_DIR/deposit_data_new.json" -m "$VAULT_DATA_DIR/deposit_data.json"

}

post_wallet_address_to_dappmanager() {
    # Read JSON from PRIVATE_KEY_FILE and extract the publicKey
    WALLET_ADDRESS=$(jq -r '.address' "${WALLET_FILE_PATH}")

    # Post ENR to dappmanager
    curl --connect-timeout 5 \
        --max-time 10 \
        --silent \
        --retry 5 \
        --retry-delay 0 \
        --retry-max-time 40 \
        -X POST "http://dappmanager.dappnode/data-send?key=Hot%20Wallet%20Address&data=0x${WALLET_ADDRESS}" ||
        {
            echo -e "[ERROR] failed to post hot wallet address to dappmanager\n"
        }
}

upload_keystores_to_brain() {
    echo "[INFO] Uploading keystores to brain..."

    operator remote-signer-setup \
        --data-dir "${STAKEWISE_DIR}" \
        --vault "${VAULT_CONTRACT_ADDRESS}" \
        --remote-signer-url "${BRAIN_URL}" \
        --dappnode \
        --execution-endpoints "${EXECUTION_RPC_API_URL}"

    status=$?
    if [ $status -ne 0 ]; then
        echo "[ERROR] Failed to upload keystores to brain. Make sure your ${NETWORK} Web3Signer is up and running."
        exit 1
    fi
}

start_operator() {
    echo "[INFO] Starting operator for ${VAULT_CONTRACT_ADDRESS}..."

    # shellcheck disable=SC2086
    # operator shortcut does not work with the exec command
    exec python3 /app/src/main.py start \
        --log-level "${LOG_LEVEL}" \
        --log-format plain \
        --vault "${VAULT_CONTRACT_ADDRESS}" \
        --execution-endpoints "${EXECUTION_RPC_API_URL}" \
        --consensus-endpoints "${BEACON_API_URL}" \
        --enable-metrics \
        --metrics-port 8008 \
        --metrics-host 0.0.0.0 \
        --network "${NETWORK}" \
        --data-dir "${STAKEWISE_DIR}" \
        --database-dir "${DATABASE_DIR}" ${EXTRA_OPTS}
}

main() {
    load_envs
    create_directories
    init_operator
    create_wallet
    ensure_number_of_validators
    post_wallet_address_to_dappmanager
    upload_keystores_to_brain
    start_operator
}

main
