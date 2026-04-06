#!/usr/bin/env bash

set -exao pipefail

# Validate required Ceph configuration files
echo "Validating Ceph configuration..."

if [[ ! -f /etc/ceph/ceph.conf ]]; then
    echo "Error: /etc/ceph/ceph.conf not found!"
    echo "Please mount the Ceph configuration directory with:"
    echo "  -v /host/path/to/ceph:/etc/ceph"
    exit 1
fi

if [[ ! -f /etc/ceph/ceph.client.admin.keyring ]]; then
    echo "Error: /etc/ceph/ceph.client.admin.keyring not found!"
    echo "Please ensure the Ceph keyring file exists in the mounted directory."
    exit 1
fi

echo "Ceph configuration files validated successfully"

# Check ceph version
ceph version

# Generate admin.key from keyring
echo "Generating admin.key from ceph.client.admin.keyring..."
ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > /etc/ceph/admin.key
echo "admin.key generated successfully"

# Display setup and usage instructions
cat << 'EOF'

================================================================================
                    FIO Test Suite - Container Setup
================================================================================

CONTAINER SETUP:
----------------
podman run -d --name <container-name> \
    --privileged \
    --net host \
    -v /host/path/to/ceph:/etc/ceph \
    -v /host/test/dir:/root/test \
    <image-name>

NOTES:
- Mount the entire Ceph config directory (must contain ceph.conf and ceph.client.admin.keyring)
- admin.key is automatically generated from ceph.client.admin.keyring at startup

MOUNT CEPH FILESYSTEM:
----------------------
mount -t ceph <mon-node-ip>:<mon-port>:/ /mnt \
    -o name=admin,secretfile=/etc/ceph/admin.key

RUN FIO TESTS:
--------------
# Set required environment variables
export FSIZE=100G
export FNAME=/mnt/testfile
export TEST_DIR=/root/test

# Optional: Configure FIO parameters
export FIO_IOENGINE=sync
export FIO_IODEPTH=64
export FIO_NUMJOBS=1
export FIO_RUNTIME=300

# Run the test suite
cd /fio
./run-fio.sh

QUICK START:
------------
1. Enter the container:
   podman exec -it <container-name> bash

2. Mount Ceph filesystem (if not already mounted)

3. Set environment variables and run tests

For more information, see /fio/README.md

================================================================================

EOF

# Let it run as long as it can
tail -f /dev/null