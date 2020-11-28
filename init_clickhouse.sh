#!/bin/bash


if [ ! -z ${BASH_SOURCE} ]; then
    if [ -z ${DODEV} ]; then
        echo "Please, set DODEV env variable"
        exit 1
    fi
	ssh -A ${DODEV} "bash -s" -- < ${BASH_SOURCE}
	exit
fi

set -ue

git clone --recursive git@github.com:vdimir/ClickHouse.git
git -C ClickHouse remote add upstream git@github.com:ClickHouse/ClickHouse.git
git -C ClickHouse fetch origin

mkdir -p asan_build

cmake -S ClickHouse -B asan_build \
	-DCMAKE_C_COMPILER=$(which clang-10) \
	-DCMAKE_CXX_COMPILER=$(which clang++-10) \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DSANITIZE=address \
    -DENABLE_CLICKHOUSE_ALL=OFF \
    -DENABLE_CLICKHOUSE_SERVER=ON \
    -DENABLE_CLICKHOUSE_CLIENT=ON \
    -DENABLE_LIBRARIES=OFF \
    -DENABLE_UTILS=OFF \
    -DCLICKHOUSE_SPLIT_BINARY=ON

