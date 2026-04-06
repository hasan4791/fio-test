# FIO Test Suite

A comprehensive bash-based test suite for running and analyzing FIO (Flexible I/O Tester) benchmarks with various block sizes and I/O patterns. Available as both standalone scripts and containerized solution with Ceph support.

## Overview

This suite consists of two main scripts:
- **run-fio.sh**: Orchestrates FIO tests across multiple block sizes and I/O patterns
- **fio-extract-data.sh**: Extracts and aggregates performance metrics from FIO output

## Features

- ✅ Comprehensive error handling and input validation
- ✅ Configurable test parameters via environment variables
- ✅ Automated testing across multiple block sizes (4k, 16k, 64k, 128k, 1024k)
- ✅ Support for read, write, and random read/write patterns
- ✅ Automatic result aggregation and extraction
- ✅ Robust error checking and cleanup
- ✅ Container support with Ceph integration
- ✅ Ready-to-use container image with all dependencies

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
  - [Standalone Usage](#standalone-usage)
  - [Container Usage](#container-usage)
- [Configuration Options](#configuration-options)
- [Container Deployment](#container-deployment)
- [Test Matrix](#test-matrix)
- [Output](#output)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Standalone Usage
- **FIO**: Flexible I/O Tester must be installed
  ```bash
  # Ubuntu/Debian
  sudo apt-get install fio
  
  # RHEL/CentOS
  sudo yum install fio
  
  # macOS
  brew install fio
  ```

### Container Usage
- **Podman** or **Docker** container runtime
- Ceph configuration files (for Ceph filesystem testing)

## Quick Start

### Standalone Usage

```bash
# Set required environment variables
export FSIZE=100G
export FNAME=/mnt/data/testfile
export TEST_DIR=/tmp/fio-test

# Run the test suite
./run-fio.sh
```

### Advanced Configuration

```bash
# Set required variables
export FSIZE=500G
export FNAME=/mnt/nvme/testfile
export TEST_DIR=/var/fio-results

# Optional: Configure FIO parameters
export FIO_IOENGINE=libaio    # I/O engine (default: sync)
export FIO_IODEPTH=64         # I/O queue depth (default: 64)
export FIO_NUMJOBS=4          # Number of parallel jobs (default: 1)
export FIO_RUNTIME=600        # Runtime in seconds (default: 300)

# Run tests
./run-fio.sh
```

## Configuration Options

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FSIZE` | Size of test file | `100G`, `500M`, `1T` |
| `FNAME` | Full path to test file | `/mnt/data/testfile` |
| `TEST_DIR` | Directory for test results | `/tmp/fio-test` |

### Optional Environment Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `FIO_IOENGINE` | I/O engine to use | `sync` | `sync`, `libaio`, `io_uring`, `psync` |
| `FIO_IODEPTH` | I/O queue depth | `64` | Any positive integer |
| `FIO_NUMJOBS` | Number of parallel jobs | `1` | Any positive integer |
| `FIO_RUNTIME` | Test runtime in seconds | `300` | Any positive integer |

## Test Matrix

The suite automatically runs tests with the following combinations:

### Block Sizes
- 4k
- 16k
- 64k
- 128k
- 1024k (1M)

### I/O Patterns
- **read**: Sequential read
- **write**: Sequential write
- **randrw**: Random read/write (50/50 mix)

This results in **15 total tests** (5 block sizes × 3 I/O patterns).

## Output

### Directory Structure

```
TEST_DIR/
├── results/
│   ├── fio-read-4k.out
│   ├── fio-write-4k.out
│   ├── fio-randrw-4k.out
│   ├── ... (15 files total)
└── fio-data-all.out (aggregated results)
```

### Result Files

- **Individual test outputs**: `TEST_DIR/results/fio-{pattern}-{blocksize}.out`
- **Aggregated results**: `TEST_DIR/fio-data-all.out`
- **Console output**: Summary of bandwidth and IOPS for each test

### Sample Output

```
Total read 4k BW is 245678.50 KiB/s
Total read 4k IOPs is 61419
---
Total write 4k BW is 198234.75 KiB/s
Total write 4k IOPs is 49558
---
Total randrw 4k read BW is 123456.25 KiB/s
Total randrw 4k read IOPs is 30864
Total randrw 4k write BW is 121098.50 KiB/s
Total randrw 4k write IOPs is 30274
Total randrw 4k read+write BW is 244554.75 KiB/s
Total randrw 4k read+write IOPs is 61138
---
```

## Script Details

### run-fio.sh

Main orchestration script that:
1. Validates all input parameters
2. Creates necessary directories
3. Runs FIO tests for all block size and I/O pattern combinations
4. Aggregates results into a single file
5. Calls extraction script to display summaries

**Key Features:**
- Strict error handling (`set -euo pipefail`)
- Comprehensive input validation
- Automatic cleanup on failure
- Progress indicators
- Configurable via environment variables

### fio-extract-data.sh

Data extraction and aggregation script that:
1. Parses FIO output files
2. Extracts bandwidth and IOPS metrics
3. Calculates totals across multiple runs
4. Displays formatted results

**Usage:**
```bash
./fio-extract-data.sh <file> <test> <bs>

# Example
./fio-extract-data.sh /tmp/fio-test/fio-data-all.out read 4k
```

## Best Practices

### Storage Testing

1. **Use direct I/O**: The scripts use `--direct=1` to bypass OS cache
2. **Sufficient file size**: Use file sizes larger than system RAM to avoid cache effects
3. **Appropriate I/O engine**: 
   - `libaio` for Linux with native async I/O
   - `io_uring` for modern Linux kernels (5.1+)
   - `sync` for basic testing (not recommended for production)

### Performance Considerations

1. **I/O Depth**: Higher values (64-128) for SSDs, lower (1-32) for HDDs
2. **Number of Jobs**: Match to storage parallelism capabilities
3. **Runtime**: Longer tests (300-600s) provide more stable results
4. **Block Size**: Test multiple sizes to understand workload characteristics

### Safety

1. **Backup data**: FIO tests can overwrite data
2. **Dedicated test files**: Use separate files/partitions for testing
3. **Monitor system**: Watch for thermal throttling or resource exhaustion
4. **Verify permissions**: Ensure write access to test locations

## Troubleshooting

### Common Issues

**Error: 'fio' command not found**
```bash
# Install FIO using your package manager
sudo apt-get install fio  # Ubuntu/Debian
sudo yum install fio      # RHEL/CentOS
```

**Error: Directory is not writable**
```bash
# Check permissions
ls -ld /path/to/directory

# Fix permissions if needed
sudo chmod 755 /path/to/directory
```

**Error: Invalid size format**
```bash
# Use correct format: number + unit
export FSIZE=100G   # Correct
export FSIZE=100    # Wrong - missing unit
```

**Tests running slowly**
- Check if `time_based=0` is appropriate for your use case
- Verify storage isn't throttling
- Consider reducing `FIO_RUNTIME` for initial tests

## Makefile Reference

The Makefile provides convenient commands for container management:

### Build Commands
- `make build` - Build the container image
- `make help` - Display all available commands and configuration

### Container Lifecycle
- `make run` - Build and run container with volume mounts
- `make start` - Start existing container
- `make stop` - Stop running container
- `make restart` - Restart container
- `make remove` - Remove container

### Container Interaction
- `make shell` - Open bash shell in container
- `make exec CMD='command'` - Execute command in container
- `make logs` - View container logs
- `make status` - Show container status

### Testing Commands
- `make mount-ceph` - Mount Ceph filesystem in container
- `make run-tests` - Run FIO tests (requires Ceph mounted)

### Cleanup
- `make clean` - Stop and remove container
- `make prune` - Remove container and image

### Configuration Variables

Override these when running make commands:

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE_NAME` | `fio-test-suite` | Container image name |
| `IMAGE_TAG` | `latest` | Container image tag |
| `CONTAINER_NAME` | `fio-test` | Container name |
| `CEPH_DIR` | `/etc/ceph` | Path to Ceph config directory |
| `RESULTS_DIR` | `./fio-results` | Host directory for results |
| `CEPH_MON_IP` | `localhost` | Ceph monitor IP |
| `CEPH_MON_PORT` | `6789` | Ceph monitor port |
| `FSIZE` | `100G` | FIO test file size |
| `FNAME` | `/mnt/fio-testfile` | FIO test file path |
| `FIO_IOENGINE` | `sync` | FIO I/O engine |
| `FIO_IODEPTH` | `64` | FIO I/O depth |
| `FIO_NUMJOBS` | `1` | FIO number of jobs |
| `FIO_RUNTIME` | `300` | FIO runtime in seconds |

**Note:** The `CEPH_DIR` should contain:
- `ceph.conf` - Ceph cluster configuration
- `ceph.client.admin.keyring` - Ceph authentication keyring
- `admin.key` will be auto-generated from the keyring

### Makefile Examples

```bash
# Quick start with defaults
make build
make run
make shell

# Custom Ceph configuration
make run \
  CEPH_DIR=/custom/path/to/ceph \
  RESULTS_DIR=/var/fio-results

# Mount Ceph with custom monitor
make mount-ceph CEPH_MON_IP=10.0.0.5 CEPH_MON_PORT=6789

# Run tests with custom parameters
make run-tests \
  FSIZE=500G \
  FIO_IOENGINE=libaio \
  FIO_IODEPTH=128 \
  FIO_NUMJOBS=8 \
  FIO_RUNTIME=600

# Complete workflow
make build                          # Build image
make run RESULTS_DIR=/var/fio       # Start container
make mount-ceph CEPH_MON_IP=10.0.0.5  # Mount Ceph
make run-tests FSIZE=200G           # Run tests
make logs                           # View output
make clean                          # Cleanup
```

## Container Deployment

### Building the Container Image

```bash
# Build the container image
podman build -t fio-test-suite:latest -f Containerfile .
```

### Running the Container

#### Basic Container Setup

```bash
podman run -d --name fio-test \
    --privileged \
    --net host \
    -v /host/path/to/ceph:/etc/ceph:ro \
    -v /host/test/dir:/root/test \
    fio-test-suite:latest
```

**Volume Mounts Explained:**
- `/etc/ceph`: Ceph configuration directory (mounted read-only)
  - Must contain `ceph.conf` and `ceph.client.admin.keyring`
  - `admin.key` is automatically generated at startup
- `/root/test`: Directory for storing test results

**Note:** The `admin.key` file is automatically generated at container startup from the `ceph.client.admin.keyring` using:
```bash
ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > /etc/ceph/admin.key
```

#### Accessing the Container

```bash
# Enter the running container
podman exec -it fio-test bash
```

### Running Tests in Container

#### Step 1: Mount Ceph Filesystem

```bash
# Inside the container
mount -t ceph <mon-node-ip>:<mon-port>:/ /mnt \
    -o name=admin,secretfile=/etc/ceph/admin.key

# Example with specific monitor
mount -t ceph 192.168.1.10:6789:/ /mnt \
    -o name=admin,secretfile=/etc/ceph/admin.key

# Verify mount
df -h /mnt
```

#### Step 2: Configure Environment Variables

```bash
# Required variables
export FSIZE=100G
export FNAME=/mnt/testfile
export TEST_DIR=/root/test

# Optional: Tune FIO parameters
export FIO_IOENGINE=libaio
export FIO_IODEPTH=64
export FIO_NUMJOBS=1
export FIO_RUNTIME=300
```

#### Step 3: Run Tests

```bash
# Navigate to FIO directory
cd /fio

# Execute test suite
./run-fio.sh
```

### Container Management

```bash
# View container logs
podman logs fio-test

# Stop container
podman stop fio-test

# Start container
podman start fio-test

# Remove container
podman rm fio-test

# View running containers
podman ps
```

### Complete Container Workflow Example

```bash
# 1. Build image
podman build -t fio-test-suite:latest -f Containerfile .

# 2. Run container with volume mounts
podman run -d --name fio-ceph-test \
    --privileged \
    --net host \
    -v /etc/ceph:/etc/ceph:ro \
    -v /var/fio-results:/root/test \
    fio-test-suite:latest

# 3. Enter container
podman exec -it fio-ceph-test bash

# 4. Inside container - mount Ceph
mount -t ceph 192.168.1.10:6789:/ /mnt -o name=admin,secretfile=/etc/ceph/admin.key

# 5. Configure and run tests
export FSIZE=100G
export FNAME=/mnt/fio-testfile
export TEST_DIR=/root/test
cd /fio
./run-fio.sh

# 6. View results (from host)
ls -lh /var/fio-results/
cat /var/fio-results/fio-data-all.out
```

## Examples

### Standalone Examples

#### Quick NVMe Test
```bash
export FSIZE=50G
export FNAME=/mnt/nvme0n1/fio-test
export TEST_DIR=/tmp/nvme-results
export FIO_IOENGINE=io_uring
export FIO_IODEPTH=128
export FIO_NUMJOBS=4
./run-fio.sh
```

### HDD Baseline Test
```bash
export FSIZE=100G
export FNAME=/mnt/hdd/fio-test
export TEST_DIR=/tmp/hdd-results
export FIO_IOENGINE=libaio
export FIO_IODEPTH=32
export FIO_NUMJOBS=1
export FIO_RUNTIME=600
./run-fio.sh
```

#### Network Storage Test
```bash
export FSIZE=20G
export FNAME=/mnt/nfs/fio-test
export TEST_DIR=/tmp/nfs-results
export FIO_IOENGINE=sync
export FIO_IODEPTH=1
export FIO_NUMJOBS=8
./run-fio.sh
```

### Container Examples

#### Ceph Performance Test

```bash
# Inside container after mounting Ceph
export FSIZE=200G
export FNAME=/mnt/ceph-perf-test
export TEST_DIR=/root/test
export FIO_IOENGINE=libaio
export FIO_IODEPTH=128
export FIO_NUMJOBS=4
export FIO_RUNTIME=600

cd /fio
./run-fio.sh
```

#### Quick Container Test (Small Dataset)

```bash
# For quick validation
export FSIZE=10G
export FNAME=/mnt/quick-test
export TEST_DIR=/root/test
export FIO_RUNTIME=60

cd /fio
./run-fio.sh
```

#### Multi-Job Parallel Test

```bash
# Test with multiple parallel jobs
export FSIZE=500G
export FNAME=/mnt/parallel-test
export TEST_DIR=/root/test
export FIO_IOENGINE=libaio
export FIO_IODEPTH=64
export FIO_NUMJOBS=8
export FIO_RUNTIME=300

cd /fio
./run-fio.sh
```

## Container Troubleshooting

### Ceph Mount Issues

**Problem: Cannot mount Ceph filesystem**
```bash
# Check Ceph cluster status
ceph -s

# Verify monitor connectivity
ping <mon-node-ip>

# Check authentication
ceph auth list

# Verify keyring permissions
ls -l /etc/ceph/ceph.client.admin.keyring
```

**Problem: Permission denied when mounting**
```bash
# Ensure container runs with --privileged flag
podman run -d --name fio-test --privileged ...

# Check if admin.key was generated successfully
cat /etc/ceph/admin.key

# If admin.key is missing, check if keyring exists
ls -l /etc/ceph/ceph.client.admin.keyring

# Manually regenerate if needed
ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > /etc/ceph/admin.key
```

### Container Access Issues

**Problem: Cannot access container**
```bash
# Check if container is running
podman ps -a

# View container logs
podman logs fio-test

# Restart container if needed
podman restart fio-test
```

**Problem: Volume mounts not working**
```bash
# Verify Ceph directory exists and contains required files
ls -l /etc/ceph/
ls -l /etc/ceph/ceph.conf
ls -l /etc/ceph/ceph.client.admin.keyring

# Check SELinux context (if applicable)
ls -Z /etc/ceph/

# Add :Z flag for SELinux
podman run -v /etc/ceph:/etc/ceph:Z ...
```

**Problem: admin.key not generated**
```bash
# Check container logs for generation errors
podman logs fio-test | grep admin.key

# Verify Ceph directory is mounted correctly
podman exec fio-test ls -l /etc/ceph/

# Check if keyring exists
podman exec fio-test ls -l /etc/ceph/ceph.client.admin.keyring

# Manually generate inside container if needed
podman exec fio-test bash -c "ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > /etc/ceph/admin.key"
```

## Contributing

Improvements and bug fixes are welcome! Please ensure:
- Scripts follow bash best practices
- All variables are properly quoted
- Error handling is comprehensive
- Changes are tested on multiple systems

## License

See LICENSE file for details.

## References

- [FIO Documentation](https://fio.readthedocs.io/)
- [FIO GitHub Repository](https://github.com/axboe/fio)
- [Linux I/O Engines](https://www.kernel.org/doc/html/latest/block/index.html)