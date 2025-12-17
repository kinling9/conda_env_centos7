#!/bin/bash
set -e

HOST_BACKUP_DIR="./backup_output"
rm -rf "$HOST_BACKUP_DIR"

# 1. Initial run (Base backup)
# No package, just creates Level 0 of empty env (or whatever is in Dockerfile)
./backup.sh

# 2. Install Pandas
# This should: Start new container -> Restore Level 0 -> Install Pandas -> Pack Level 1
./backup.sh pandas

# 3. Install Numpy
# This should: Start new container -> Restore Level 0, Level 1 -> Install Numpy (already there) -> Pack Level 2
# We check if Level 2 is small.
./backup.sh numpy

# 4. Multi-package Install (Implicit Conda)
echo "Testing multi-package install (pytz six)..."
./backup.sh pytz six

# 5. Complex Install Command (Pip with flags)
echo "Testing complex pip install..."
./backup.sh pip install --no-cache-dir toml

echo "=== Stateless Test Workflow Completed ==="
ls -lh "$HOST_BACKUP_DIR"
