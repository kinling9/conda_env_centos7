#!/bin/bash

# Configuration
IMAGE_NAME="conda-glibc217-env"
HOST_BACKUP_DIR="./backup_output"
CONTAINER_BACKUP_DIR="/opt/packed_updates"
ENV_NAME="test_env"

# 1. Build the Docker image
echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# Create host backup directory if it doesn't exist
mkdir -p "$HOST_BACKUP_DIR"

PACKAGE_TO_INSTALL="$1"

if [ -z "$PACKAGE_TO_INSTALL" ]; then
    echo "Usage: ./backup.sh [package_name]"
    echo "If no package name is provided, it will just restore and backup (snapshot)."
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

# Step B: Install new package (if requested)
if [ ! -z "$PACKAGE_TO_INSTALL" ]; then
    CMD_STRING="$CMD_STRING && echo '--- Installing $PACKAGE_TO_INSTALL ---' && conda install -y $PACKAGE_TO_INSTALL"
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