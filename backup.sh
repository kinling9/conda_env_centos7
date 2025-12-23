#!/bin/bash

# Configuration
IMAGE_NAME="conda-glibc217-env"
HOST_BACKUP_DIR="./backup_output"
CONTAINER_BACKUP_DIR="/opt/packed_updates"
ENV_NAME="gcn_env"

# 1. Build the Docker image
echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# Create host backup directory if it doesn't exist
mkdir -p "$HOST_BACKUP_DIR"

INPUT_ARGS="$*"

if [ -z "$INPUT_ARGS" ]; then
    echo "Usage: ./backup.sh [package_name|install_command]"
    echo "If no arguments are provided, it will just restore and backup (snapshot)."
fi

# 2. Run the Docker container
# We run a NEW container every time to ensure statelessness (simulating 'backup docker may be killed')
echo "Running Docker container..."
echo "Mounting: $(pwd)/$HOST_BACKUP_DIR -> $CONTAINER_BACKUP_DIR"

CMD_STRING="source /root/miniconda3/etc/profile.d/conda.sh && conda activate $ENV_NAME"

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
CMD_STRING="$CMD_STRING && echo '--- Packing Updates ---' && /usr/local/bin/pack_incremental.sh $ENV_NAME"

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
