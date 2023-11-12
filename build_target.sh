#! /usr/bin/env bash

rust_arch="$1"
c_arch="$2"
host_arch="$3"

mkdir -p build/$rust_arch
mkdir -p build/bundle/$rust_arch
cd build/$rust_arch

if [[ $rust_arch =~ .*android.* ]];
then
	abi="33"

	export CC="$c_arch$abi-clang"
	export CXX="$c_arch$abi-clang++"
fi

if [[ $rust_arch =~ .*linux-gnu ]];
then
	export CC="x86_64-linux-gnu-gcc"
	export CXX="x86_64-linux-gnu-g++"
fi

if [[ $rust_arch =~ .*apple.* ]] || [[ $rust_arch =~ .*androideabi ]];
then
	export EXTRA_ARGS="LDFLAGS=\"-lpthread\""
fi

CFLAGS="-I../../src/include -I../../src/include/compat" \
	../../configure \
	--enable-static \
	--disable-shared \
	--without-speechplayer \
	--without-sonic \
	--without-pcaudiolib \
	--host=$host_arch \
	--target=$c_arch \
	$EXTRA_ARGS

make SHELL="/bin/bash -x" -j 16 src/espeak-ng; ex=$? || true
cp src/.libs/libespeak-ng.a ../bundle/$rust_arch/libespeak-ng.a
exit $ex
