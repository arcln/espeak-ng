#! /usr/bin/env bash

set -e
cd $(dirname $0)

function build_target {
	rust_arch="$1"
	c_arch="$2"

	mkdir -p build/$rust_arch
	mkdir -p build/bundle/$rust_arch
	cd build/$rust_arch

	CFLAGS="-I../../src/include -I../../src/include/compat" \
		../../configure \
		--disable-shared \
		--without-speechplayer \
		--host=aarch64-apple-darwin \
		--target=$c_arch

	make -j 16 src/espeak-ng
	cp src/.libs/libespeak-ng.a ../../build/bundle/$rust_arch/libespeak-ng.a

	cd -
}

function with_xcode_sdk {
	CC="xcrun -sdk $1 clang -arch arm64" \
	CXX="xcrun -sdk $1 clang++ -arch arm64" \
	LD="xcrun -sdk $1 ld" \
	AR="xcrun -sdk $1 ar" \
	RANLIB="xcrun -sdk $1 ranlib" \
	${@:2}
}

function build_data {
	./configure --disable-shared --without-speechplayer
	make -j 16 src/espeak-ng
	make

	cp -r espeak-ng-data build/bundle
	rm -rf build/bundle/mbrola_ph build/bundle/voices
}

function export_data {
	cd build/bundle
	zip -r ../libespeak-ng.zip .
	cd -
}

make distclean || true
./autogen.sh

rm -rf build
mkdir -p build/bundle

build_target "aarch64-apple-darwin" "aarch64-apple-darwin"
with_xcode_sdk "iphoneos" build_target "aarch64-apple-ios" "aarch64-apple-ios"
with_xcode_sdk "iphonesimulator" build_target "aarch64-apple-ios-sim" "aarch64-apple-ios-simulator"

build_data
export_data
