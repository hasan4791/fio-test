#!/bin/bash

# Strict error handling
set -euo pipefail

# Usage function
usage() {
    cat << EOF
Usage: $0 <file> <test> <bs>

Arguments:
  file    Path to the FIO results file
  test    Test type: read, write, or randrw
  bs      Block size: 4k, 16k, 64k, 128k, or 1024k

Example:
  $0 /path/to/fio-data-all.out read 4k
EOF
    exit 1
}

# Validate arguments
if [[ $# -ne 3 ]]; then
    echo "Error: Expected 3 arguments, got $#" >&2
    usage
fi

file="$1"
test="$2"
bs="$3"

# Validate file exists
if [[ ! -e "${file}" ]]; then
    echo "Error: File '${file}' does not exist" >&2
    exit 1
fi

if [[ ! -r "${file}" ]]; then
    echo "Error: File '${file}' is not readable" >&2
    exit 1
fi

# Validate test type
case "${test}" in
    read|write|randrw)
        ;;
    *)
        echo "Error: Invalid test type '${test}'. Expected: read, write, or randrw" >&2
        usage
        ;;
esac

# Validate block size
case "${bs}" in
    4k|16k|64k|128k|1024k)
        ;;
    *)
        echo "Error: Invalid block size '${bs}'. Expected: 4k, 16k, 64k, 128k, or 1024k" >&2
        usage
        ;;
esac

# Calculate total bandwidth from array of bandwidth values
calc_bw() {
    local -a lbw=("$@")
    local totalBW=0
    local KiBs=0
    local Bytes=0
    local MBytes=0
    
    for i in "${lbw[@]}"; do
        if [[ "${i}" =~ K$ ]]; then
            KiBs="${i%K}"
        elif [[ "${i}" =~ B$ ]]; then
            Bytes="${i%B}"
            KiBs=$(awk -v j="${Bytes}" 'BEGIN {printf "%.2f", j/1024}')
        elif [[ "${i}" =~ M$ ]]; then
            MBytes="${i%M}"
            KiBs=$(awk -v j="${MBytes}" 'BEGIN {printf "%.2f", j*1024}')
        else
            echo "Warning: Unknown bandwidth unit in '${i}', skipping" >&2
            continue
        fi
        
        totalBW=$(awk -v t="${totalBW}" -v k="${KiBs}" 'BEGIN {printf "%.2f", t+k}')
    done
    
    echo "${totalBW}"
}

# Calculate total IOPS from array of IOPS values
calc_iops() {
    local -a liops=("$@")
    local totalIOPs=0
    
    for i in "${liops[@]}"; do
        if [[ "${i}" =~ ^[0-9]+$ ]]; then
            totalIOPs=$((totalIOPs + i))
        else
            echo "Warning: Invalid IOPS value '${i}', skipping" >&2
        fi
    done
    
    echo "${totalIOPs}"
}

# Extract and process results based on test type
case "${test}" in
    read|write)
        # Extract lines for this test and block size
        lines=$(awk "/${test}-${bs}/{print;getline;print}" "${file}")
        
        if [[ -z "${lines}" ]]; then
            echo "Warning: No data found for ${test}-${bs}" >&2
            exit 0
        fi
        
        # Extract bandwidth values
        mapfile -t bw < <(echo "${lines}" | grep IOPS | awk '{print $3}' | \
            sed 's/BW=//' | sed 's/KiB\/s/K/' | sed 's/MiB\/s/M/' | sed 's/B\/s/B/')
        
        # Extract IOPS values
        mapfile -t iops < <(echo "${lines}" | grep IOPS | awk '{print $2}' | \
            sed 's/IOPS=//' | sed 's/,//')
        
        if [[ ${#bw[@]} -eq 0 ]]; then
            echo "Warning: No bandwidth data found for ${test}-${bs}" >&2
            exit 0
        fi
        
        # Calculate totals
        totalBW=$(calc_bw "${bw[@]}")
        totalIOPs=$(calc_iops "${iops[@]}")
        
        # Display results
        echo "Total ${test} ${bs} BW is ${totalBW} KiB/s"
        echo "Total ${test} ${bs} IOPs is ${totalIOPs}"
        echo "---"
        ;;
        
    randrw)
        # Extract lines for randrw test
        lines=$(awk "/${test}-${bs}/{print;getline;print;getline;print}" "${file}")
        
        if [[ -z "${lines}" ]]; then
            echo "Warning: No data found for ${test}-${bs}" >&2
            exit 0
        fi
        
        # Extract read bandwidth and IOPS
        mapfile -t readBW < <(echo "${lines}" | grep "read: IOPS" | awk '{print $3}' | \
            sed 's/BW=//' | sed 's/KiB\/s/K/' | sed 's/MiB\/s/M/' | sed 's/B\/s/B/')
        
        mapfile -t readIOPs < <(echo "${lines}" | grep "read: IOPS" | awk '{print $2}' | \
            sed 's/IOPS=//' | sed 's/,//')
        
        # Extract write bandwidth and IOPS
        mapfile -t writeBW < <(echo "${lines}" | grep "write: IOPS" | awk '{print $3}' | \
            sed 's/BW=//' | sed 's/KiB\/s/K/' | sed 's/MiB\/s/M/' | sed 's/B\/s/B/')
        
        mapfile -t writeIOPs < <(echo "${lines}" | grep "write: IOPS" | awk '{print $2}' | \
            sed 's/IOPS=//' | sed 's/,//')
        
        if [[ ${#readBW[@]} -eq 0 && ${#writeBW[@]} -eq 0 ]]; then
            echo "Warning: No data found for ${test}-${bs}" >&2
            exit 0
        fi
        
        # Calculate read totals
        totalReadBW=0
        totalReadIOPs=0
        if [[ ${#readBW[@]} -gt 0 ]]; then
            totalReadBW=$(calc_bw "${readBW[@]}")
            totalReadIOPs=$(calc_iops "${readIOPs[@]}")
        fi
        
        echo "Total ${test} ${bs} read BW is ${totalReadBW} KiB/s"
        echo "Total ${test} ${bs} read IOPs is ${totalReadIOPs}"
        
        # Calculate write totals
        totalWriteBW=0
        totalWriteIOPs=0
        if [[ ${#writeBW[@]} -gt 0 ]]; then
            totalWriteBW=$(calc_bw "${writeBW[@]}")
            totalWriteIOPs=$(calc_iops "${writeIOPs[@]}")
        fi
        
        echo "Total ${test} ${bs} write BW is ${totalWriteBW} KiB/s"
        echo "Total ${test} ${bs} write IOPs is ${totalWriteIOPs}"
        
        # Calculate combined totals
        totalBW=$(awk -v a="${totalReadBW}" -v b="${totalWriteBW}" \
            'BEGIN {printf "%.2f", a+b}')
        totalIOPs=$((totalReadIOPs + totalWriteIOPs))
        
        echo "Total ${test} ${bs} read+write BW is ${totalBW} KiB/s"
        echo "Total ${test} ${bs} read+write IOPs is ${totalIOPs}"
        echo "---"
        ;;
esac

exit 0

# Made with Bob
