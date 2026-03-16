#!/bin/bash

# Strict error handling
set -euo pipefail

# Script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        echo "Error: Script failed with exit code ${exit_code}" >&2
        if [[ -d "${TEST_DIR:-}/results" ]]; then
            echo "Check ${TEST_DIR}/results for partial results" >&2
        fi
    fi
}

trap cleanup EXIT

usage() {
    cat << EOF
Usage: Set the following environment variables before running:
  export FSIZE=500G          # File size (e.g., 500G, 1T, 100M)
  export FNAME=/mnt/path/filename  # Full path to test file
  export TEST_DIR=/fio/test/directory  # Directory for test results

Optional:
  export FIO_IOENGINE=libaio  # I/O engine (default: sync)
  export FIO_IODEPTH=64       # I/O depth (default: 64)
  export FIO_NUMJOBS=1        # Number of jobs (default: 1)
  export FIO_RUNTIME=300      # Runtime in seconds (default: 300)

Example:
  export FSIZE=100G
  export FNAME=/mnt/data/testfile
  export TEST_DIR=/tmp/fio-test
  ./run-fio.sh
EOF
    exit 1
}

print_vars() {
    echo "=== FIO Test Configuration ==="
    echo "Test directory: ${TEST_DIR}"
    echo "File size: ${FSIZE}"
    echo "File name: ${FNAME}"
    echo "I/O engine: ${FIO_IOENGINE}"
    echo "I/O depth: ${FIO_IODEPTH}"
    echo "Number of jobs: ${FIO_NUMJOBS}"
    echo "Runtime: ${FIO_RUNTIME}s"
    echo "=============================="
}

validate_size_format() {
    local size="$1"
    if ! [[ "${size}" =~ ^[0-9]+[KMGT]?$ ]]; then
        echo "Error: Invalid size format '${size}'. Use format like: 100G, 500M, 1T" >&2
        return 1
    fi
}

validate_inputs() {
    # Check required variables
    if [[ -z "${FSIZE:-}" ]]; then
        echo "Error: FSIZE is not set" >&2
        usage
    fi
    
    if [[ -z "${FNAME:-}" ]]; then
        echo "Error: FNAME is not set" >&2
        usage
    fi
    
    if [[ -z "${TEST_DIR:-}" ]]; then
        echo "Error: TEST_DIR is not set" >&2
        usage
    fi
    
    # Validate size format
    validate_size_format "${FSIZE}"
    
    # Check if parent directory of FNAME exists and is writable
    local fname_dir
    fname_dir="$(dirname "${FNAME}")"
    if [[ ! -d "${fname_dir}" ]]; then
        echo "Error: Directory '${fname_dir}' does not exist" >&2
        exit 1
    fi
    
    if [[ ! -w "${fname_dir}" ]]; then
        echo "Error: Directory '${fname_dir}' is not writable" >&2
        exit 1
    fi
    
    # Check if TEST_DIR exists or can be created
    if [[ ! -d "${TEST_DIR}" ]]; then
        echo "Warning: TEST_DIR '${TEST_DIR}' does not exist. Creating it..." >&2
        mkdir -p "${TEST_DIR}" || {
            echo "Error: Failed to create TEST_DIR '${TEST_DIR}'" >&2
            exit 1
        }
    fi
    
    # Check if fio is installed
    if ! command -v fio &> /dev/null; then
        echo "Error: 'fio' command not found. Please install fio." >&2
        exit 1
    fi
    
    # Check if extract script exists
    if [[ ! -f "${SCRIPT_DIR}/fio-extract-data.sh" ]]; then
        echo "Error: fio-extract-data.sh not found in ${SCRIPT_DIR}" >&2
        exit 1
    fi
    
    if [[ ! -x "${SCRIPT_DIR}/fio-extract-data.sh" ]]; then
        echo "Warning: Making fio-extract-data.sh executable" >&2
        chmod +x "${SCRIPT_DIR}/fio-extract-data.sh"
    fi
}

run_fio_test() {
    local rw_type="$1"
    local block_size="$2"
    local output_file="${TEST_DIR}/results/fio-${rw_type}-${block_size}.out"
    
    echo "Running: ${rw_type} test with block size ${block_size}..."
    
    fio --name=fio-test \
        --filename="${FNAME}" \
        --rw="${rw_type}" \
        --bs="${block_size}" \
        --direct=1 \
        --numjobs="${FIO_NUMJOBS}" \
        --time_based=0 \
        --runtime="${FIO_RUNTIME}" \
        --size="${FSIZE}" \
        --ioengine="${FIO_IOENGINE}" \
        --iodepth="${FIO_IODEPTH}" \
        --output="${output_file}" \
        --randrepeat=0 || {
            echo "Error: FIO test failed for ${rw_type} ${block_size}" >&2
            return 1
        }
}

# Set defaults for optional variables
FIO_IOENGINE="${FIO_IOENGINE:-sync}"
FIO_IODEPTH="${FIO_IODEPTH:-64}"
FIO_NUMJOBS="${FIO_NUMJOBS:-1}"
FIO_RUNTIME="${FIO_RUNTIME:-300}"

# Validate all inputs
validate_inputs

# Print configuration
print_vars

# Create results directory
mkdir -p "${TEST_DIR}/results" || {
    echo "Error: Failed to create results directory" >&2
    exit 1
}

# Change to test directory
pushd "${TEST_DIR}" > /dev/null || {
    echo "Error: Failed to change to TEST_DIR" >&2
    exit 1
}

echo ""
echo "Starting FIO tests -- $(hostname) -- $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Define test parameters
BLOCK_SIZES=(4k 16k 64k 128k 1024k)
RW_TYPES=(read write randrw)

# Run all tests
for bs in "${BLOCK_SIZES[@]}"; do
    for rw in "${RW_TYPES[@]}"; do
        run_fio_test "${rw}" "${bs}"
    done
done

echo ""
echo "Completed FIO tests -- $(hostname) -- $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Aggregate results
echo "Aggregating results..."
pushd results > /dev/null || {
    echo "Error: Failed to change to results directory" >&2
    exit 1
}

# Use glob pattern instead of ls
for file in *.out; do
    if [[ -f "${file}" ]]; then
        echo "FIO ${file} results" >> ../fio-data-all.out
        grep IOPS "${file}" >> ../fio-data-all.out || true
    fi
done

popd > /dev/null

popd > /dev/null

# Extract and display results
results_file="${TEST_DIR}/fio-data-all.out"

if [[ ! -f "${results_file}" ]]; then
    echo "Error: Results file not found: ${results_file}" >&2
    exit 1
fi

echo ""
echo "FIO data file: ${results_file}"
echo ""
echo "=== Extracting Results ==="

# Extract results for all combinations
for rw in "${RW_TYPES[@]}"; do
    echo ""
    echo "--- ${rw} results ---"
    for bs in "${BLOCK_SIZES[@]}"; do
        "${SCRIPT_DIR}/fio-extract-data.sh" "${results_file}" "${rw}" "${bs}" || {
            echo "Warning: Failed to extract data for ${rw} ${bs}" >&2
        }
    done
done

echo ""
echo "=== Test Complete ==="
echo "Results saved in: ${TEST_DIR}/results"
echo "Summary file: ${results_file}"

exit 0

# Made with Bob
