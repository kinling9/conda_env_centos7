#!/bin/bash

# Configuration
IMAGE_NAME="conda-glibc217-env"
HOST_BACKUP_DIR="./backup_output"
CONTAINER_BACKUP_DIR="/opt/packed_updates"
ENV_NAME="gcn_env"
TARGET_CONDA_DIR="/root/miniconda3"

# Parse optional arguments
RESET_FLAG=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir=*)
            TARGET_CONDA_DIR="${1#*=}"
            shift
            ;;
        --target-dir)
            TARGET_CONDA_DIR="$2"
            shift 2
            ;;
        --reset|--full)
            RESET_FLAG="--reset"
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters for later use
set -- "${ARGS[@]}"

# Determine ENV_NAME based on TARGET_CONDA_DIR
# If TARGET_CONDA_DIR is the default, we keep default ENV_NAME.
# If user provided a custom path, we extract the basename as ENV_NAME.
if [ "$TARGET_CONDA_DIR" != "/root/miniconda3" ]; then
    ENV_NAME=$(basename "$TARGET_CONDA_DIR")
fi

# 1. Build the Docker image
echo "Building Docker image: $IMAGE_NAME"
echo "  - TARGET_CONDA_DIR: $TARGET_CONDA_DIR"
echo "  - ENV_NAME:         $ENV_NAME"

docker build \
    --build-arg TARGET_CONDA_DIR="$TARGET_CONDA_DIR" \
    --build-arg ENV_NAME="$ENV_NAME" \
    -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# Create host backup directory if it doesn't exist
mkdir -p "$HOST_BACKUP_DIR"

INPUT_ARGS="$*"

if [ -z "$INPUT_ARGS" ] && [ -z "$RESET_FLAG" ]; then
    echo "Usage: ./backup.sh [--target-dir=<dir>] [--reset] [package_name|install_command]"
    echo "If no arguments are provided, it will just restore and backup (snapshot)."
fi

# 2. Run the Docker container
# We run a NEW container every time to ensure statelessness (simulating 'backup docker may be killed')
echo "Running Docker container..."
echo "Mounting: $(pwd)/$HOST_BACKUP_DIR -> $CONTAINER_BACKUP_DIR"

CMD_STRING="source $TARGET_CONDA_DIR/etc/profile.d/conda.sh && conda activate $ENV_NAME"

# Step A: Restore from previous backups
CMD_STRING="$CMD_STRING && echo '--- Restoring State ---' && /usr/local/bin/restore_env.sh $ENV_NAME"

# Step A.5: Refresh Snapshot (Fix for Tar Incremental on new inodes)
CMD_STRING="$CMD_STRING && /usr/local/bin/refresh_snapshot.sh $ENV_NAME"

# Logic to determine actual install command
INSTALL_CMD=""
if [ ! -z "$INPUT_ARGS" ]; then
    # Get the first word of the arguments to check if it's a known command
    FIRST_WORD=$(echo "$INPUT_ARGS" | awk '{print $1}')

    if [[ "$FIRST_WORD" == "pip" || "$FIRST_WORD" == "conda" || "$FIRST_WORD" == "mamba" ]]; then
        # Assume user provided a full command
        INSTALL_CMD="$INPUT_ARGS"
    else
        # Assume user provided package list, default to conda install
        INSTALL_CMD="conda install -y $INPUT_ARGS"
    fi
fi

# Step B: Install new package (if requested)
if [ ! -z "$INSTALL_CMD" ]; then
    CMD_STRING="$CMD_STRING && echo '--- Installing: $INSTALL_CMD ---' && $INSTALL_CMD"
fi

# Step C: Pack incremental
CMD_STRING="$CMD_STRING && echo '--- Packing Updates ---' && /usr/local/bin/pack_incremental.sh $ENV_NAME $RESET_FLAG"

docker run --rm \
    -v "$(pwd)/$HOST_BACKUP_DIR:$CONTAINER_BACKUP_DIR" \
    "$IMAGE_NAME" \
    /bin/bash -c "$CMD_STRING"

if [ $? -ne 0 ]; then
    echo "Docker run failed."
    exit 1
fi

echo "Process completed."
echo "Artifacts are in '$HOST_BACKUP_DIR'."
