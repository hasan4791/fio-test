# FIO Test Suite

A comprehensive bash-based test suite for running and analyzing FIO (Flexible I/O Tester) benchmarks with various block sizes and I/O patterns.

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

## Prerequisites

- **FIO**: Flexible I/O Tester must be installed
  ```bash
  # Ubuntu/Debian
  sudo apt-get install fio
  
  # RHEL/CentOS
  sudo yum install fio
  
  # macOS
  brew install fio
  ```

## Quick Start

### Basic Usage

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
export FIO_IOENGINE=libaio    # I/O engine (default: libaio)
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
| `FIO_IOENGINE` | I/O engine to use | `libaio` | `libaio`, `io_uring`, `sync`, `psync` |
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

## Examples

### Quick NVMe Test
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

### Network Storage Test
```bash
export FSIZE=20G
export FNAME=/mnt/nfs/fio-test
export TEST_DIR=/tmp/nfs-results
export FIO_IOENGINE=sync
export FIO_IODEPTH=1
export FIO_NUMJOBS=8
./run-fio.sh
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