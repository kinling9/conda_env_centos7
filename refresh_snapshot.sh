#!/bin/bash
set -e

# Configuration
ENV_NAME="${1:-test_env}"
BACKUP_DIR="/opt/packed_updates"
SNAPSHOT_FILE="/tmp/${ENV_NAME}_snapshot.snar"
CONDA_BASE=$(conda info --base)
ENV_PATH="$CONDA_BASE/envs/$ENV_NAME"

touch $SNAPSHOT_FILE
# Check if snapshot exists. If not, nothing to refresh.
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "No snapshot file found at $SNAPSHOT_FILE. Skipping refresh."
    exit 0
fi

echo "=== Refreshing Snapshot Metadata ==="
echo "Snapshot: $SNAPSHOT_FILE"
echo "Environment: $ENV_PATH"
echo "Reason: Syncing snapshot inodes with current container filesystem."

# FIX: Tar incremental backup logic relies on directory modification times
# to decide whether to scan children. Restored directories have old mtimes,
# but new inodes. If we don't force a scan, tar keeps old inodes in snapshot.
# Later, if a directory mtime changes (e.g. installing a package), tar scans
# it and sees 'new' inodes for existing files, causing full repack.
# We touch all directories to force tar to re-scan and update inodes.
find "$ENV_PATH" -type d -exec touch {} +

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
