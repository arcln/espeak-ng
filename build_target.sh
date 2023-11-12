#! /usr/bin/env bash

rust_arch="$1"
c_arch="$2"
host_arch="$3"

mkdir -p build/$rust_arch
mkdir -p build/bundle/$rust_arch
cd build/$rust_arch

CFLAGS="-I../../src/include -I../../src/include/compat" \
	../../configure \
	--disable-shared \
	--without-speechplayer \
	--host=$host_arch \
	--target=$c_arch

make SHELL="/bin/bash -x" -j 16 src/espeak-ng; ex=$? || true
cp src/.libs/libespeak-ng.a ../bundle/$rust_arch/libespeak-ng.a
exit $ex
