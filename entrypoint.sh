#!/usr/bin/env bash

set -exao pipefail

# Check ceph version
ceph version

# Generate admin.key from keyring
echo "Generating admin.key from ceph.client.admin.keyring..."
if [[ -f /etc/ceph/ceph.client.admin.keyring ]]; then
    ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > /etc/ceph/admin.key
    echo "admin.key generated successfully"
else
    echo "Warning: /etc/ceph/ceph.client.admin.keyring not found. admin.key not generated."
fi

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
    -v /host/path/ceph.conf:/etc/ceph/ceph.conf \
    -v /host/path/ceph.client.admin.keyring:/etc/ceph/ceph.client.admin.keyring \
    -v /host/test/dir:/root/test \
    <image-name>

NOTE: admin.key is now generated automatically from ceph.client.admin.keyring

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