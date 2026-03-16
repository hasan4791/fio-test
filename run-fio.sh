#!/bin/bash

usage() {
    echo "Set file size: export FSIZE=500G"
    echo "Set file name: export FNAME=/mnt/path/filename"
    echo "Set fio test directory: export TEST_DIR=/fio/test/directory"
    exit 1
}

print_vars() {
    echo "Fio test directory is set to: ${TEST_DIR}"
    echo "File Size is set to : ${FSIZE}"
    echo "File NAME is set to : ${FNAME}"
}

if [[ -z "${FSIZE}" ]]; then
    usage
elif [[ -z "${FNAME}" ]]; then
    usage
elif [[ -z "${TEST_DIR}" ]]; then
    usage
else
    print_vars
    mkdir ${TEST_DIR}/results
fi

sleep 15s

pushd ${TEST_DIR} >/dev/null 2>&1

echo "Starting Fio tests -- $(hostname) -- $(date '+%D %T')" 

set -x

fio --name=fio-fillup --filename=${FNAME} --rw=read --bs=1024k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-read-1024k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=write --bs=1024k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-write-1024k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=randrw --bs=1024k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-randrw-1024k.out --randrepeat=0

fio --name=fio-fillup --filename=${FNAME} --rw=read --bs=128k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-read-128k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=write --bs=128k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-write-128k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=randrw --bs=128k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-randrw-128k.out --randrepeat=0

fio --name=fio-fillup --filename=${FNAME} --rw=read --bs=64k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-read-64k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=write --bs=64k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-write-64k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=randrw --bs=64k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-randrw-64k.out --randrepeat=0

fio --name=fio-fillup --filename=${FNAME} --rw=read --bs=16k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-read-16k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=write --bs=16k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-write-16k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=randrw --bs=16k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-randrw-16k.out --randrepeat=0

fio --name=fio-fillup --filename=${FNAME} --rw=read --bs=4k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-read-4k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=write --bs=4k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-write-4k.out --randrepeat=0
fio --name=fio-fillup --filename=${FNAME} --rw=randrw --bs=4k --direct=1 --numjobs=1 --time_based=0 --runtime=300 --size=${FSIZE} --ioengine=sync --iodepth=64 --output=results/fio-randrw-4k.out --randrepeat=0

set +x

echo "Completed Fio tests -- $(hostname) -- $(date '+%D %T')"

pushd results >/dev/null 2>&1
for files in $(ls *.out)
do
    echo "Fio $files results" >> ../fio-data-all.out
    grep IOPS $files >> ../fio-data-all.out
done
popd >/dev/null 2>&1

popd >/dev/null 2>&1

file=${TEST_DIR}/fio-data-all.out

echo -e "Fio data file: $file\n"

./fio-extract-data.sh $file read 4k
./fio-extract-data.sh $file read 16k
./fio-extract-data.sh $file read 64k
./fio-extract-data.sh $file read 128k
./fio-extract-data.sh $file read 1024k

./fio-extract-data.sh $file write 4k
./fio-extract-data.sh $file write 16k
./fio-extract-data.sh $file write 64k
./fio-extract-data.sh $file write 128k
./fio-extract-data.sh $file write 1024k

./fio-extract-data.sh $file randrw 4k
./fio-extract-data.sh $file randrw 16k
./fio-extract-data.sh $file randrw 64k
./fio-extract-data.sh $file randrw 128k
./fio-extract-data.sh $file randrw 1024k

exit
