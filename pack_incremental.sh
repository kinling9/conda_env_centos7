#!/bin/bash

# CONFIGURATION
# --------------------------
# The name of your local conda environment
ENV_NAME="${1:-my_env}"
# Where to store the generated pack files
OUTPUT_DIR="/opt/packed_updates"
# --------------------------

# Setup paths
CONDA_BASE=$(conda info --base)
ENV_PATH="$CONDA_BASE/envs/$ENV_NAME"
SNAPSHOT_FILE="/tmp/${ENV_NAME}_snapshot.snar"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_TAR="$OUTPUT_DIR/${ENV_NAME}_update_${TIMESTAMP}.tar.gz"

# Check if env exists
if [ ! -d "$ENV_PATH" ]; then
    echo "Error: Environment '$ENV_NAME' not found at $ENV_PATH"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "Packing Incremental Update for: $ENV_NAME"
echo "Source: $ENV_PATH"
echo "Snapshot DB: $SNAPSHOT_FILE"
echo "========================================"

# Logic:
# If .snar file exists, tar will use it to find ONLY changed files.
# If .snar file does NOT exist, tar will create it and pack EVERYTHING (Level 0 backup).

# rm -rf $SNAPSHOT_FILE
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "⚠️  No snapshot found. This will be a FULL backup (Level 0)."
    echo "    Upload this full file to the server first to establish the base."
else
    echo "✅ Snapshot found. Calculating changes since last pack..."
fi

# Create the archive using GNU Tar incremental mode
# We exclude standard junk files to keep it small
tar --create --file="$OUTPUT_TAR" \
    --listed-incremental="$SNAPSHOT_FILE" \
    --gzip \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='.ipynb_checkpoints' \
    -C "$ENV_PATH" .

echo "========================================"
echo "✅ Package Created: $OUTPUT_TAR"
echo "Size: $(du -h "$OUTPUT_TAR" | cut -f1)"
echo "========================================"
echo "NEXT STEPS:"
echo "1. Send $OUTPUT_TAR to your server."
echo "2. Extract it into your server environment folder."
echo "3. IMPORTANT: Run './bin/conda-unpack' on the server after extracting."
