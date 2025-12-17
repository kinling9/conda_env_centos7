#!/bin/bash
set -e

# Configuration
ENV_NAME="${1:-test_env}"
BACKUP_DIR="/opt/packed_updates"
SNAPSHOT_FILE="$BACKUP_DIR/${ENV_NAME}_snapshot.snar"
CONDA_BASE=$(conda info --base)
ENV_PATH="$CONDA_BASE/envs/$ENV_NAME"

# Check if snapshot exists. If not, nothing to refresh.
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "No snapshot file found at $SNAPSHOT_FILE. Skipping refresh."
    exit 0
fi

echo "=== Refreshing Snapshot Metadata ==="
echo "Snapshot: $SNAPSHOT_FILE"
echo "Environment: $ENV_PATH"
echo "Reason: Syncing snapshot inodes with current container filesystem."

# We run tar to update the snapshot but discard the output archive.
# We MUST use the same excludes as pack_incremental.sh to match logic.
tar --create --file=/dev/null \
    --listed-incremental="$SNAPSHOT_FILE" \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='.ipynb_checkpoints' \
    -C "$ENV_PATH" .

echo "✅ Snapshot refreshed."
