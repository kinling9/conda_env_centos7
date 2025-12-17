#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/opt/packed_updates"
ENV_NAME="${1:-test_env}"
CONDA_BASE=$(conda info --base)
TARGET_DIR="$CONDA_BASE/envs/$ENV_NAME"

echo "=== Restoring Environment '$ENV_NAME' from $BACKUP_DIR ==="

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found. Skipping restore."
    exit 0
fi

# Find tarballs for this environment, sorted by name (which effectively sorts by timestamp)
# Pattern: ${ENV_NAME}_update_*.tar.gz
TAR_FILES=$(ls -1 "$BACKUP_DIR"/${ENV_NAME}_update_*.tar.gz 2>/dev/null | sort)

if [ -z "$TAR_FILES" ]; then
    echo "No backup files found for '$ENV_NAME'. Starting fresh."
    exit 0
fi

# Ensure target directory exists (conda create should have made it, but tar needs it)
mkdir -p "$TARGET_DIR"

# Navigate to target to extract (since we packed relative to env root with -C)
# Wait, pack_incremental.sh used: -C "$ENV_PATH" .
# So we must extract into "$ENV_PATH".
cd "$TARGET_DIR"

for tarball in $TAR_FILES; do
    echo "Extracting: $tarball"
    # Use standard tar extraction. 
    # -G (incremental) is not strictly needed for extraction, usually standard -x works 
    # but for true incremental streams, sometimes -G is advised. 
    # However, these are separate tar files. Standard -x is correct.
    tar -xf "$tarball"
done

echo "✅ Restore complete."
