#! /usr/bin/env bash

set -e
cd $(dirname $0)

function with_xcode_sdk {
	CC="xcrun -sdk $1 clang -arch arm64" \
	CXX="xcrun -sdk $1 clang++ -arch arm64" \
	LD="xcrun -sdk $1 ld" \
	AR="xcrun -sdk $1 ar" \
	RANLIB="xcrun -sdk $1 ranlib" \
	${@:2}
}

function with_android_sdk {
	abi="33"

	PATH=$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH \
	CC="$1$abi-clang" \
	CXX="$1$abi-clang++" \
	LD="toto" \
	${@:2}
}

function build_data {
	./configure --disable-shared --without-speechplayer
	make -j 16 src/espeak-ng
	make

	cp -r espeak-ng-data build/bundle
	rm -rf build/bundle/mbrola_ph build/bundle/voices
}

function export_bundle {
	cd build/bundle
	zip -r ../libespeak-ng.zip .
	cd -
}

make distclean || true
./autogen.sh

rm -rf build
mkdir -p build/bundle

./build_target.sh "aarch64-apple-darwin" "aarch64-apple-darwin"
with_xcode_sdk "iphoneos" ./build_target.sh "aarch64-apple-ios" "aarch64-apple-ios"
with_xcode_sdk "iphonesimulator" ./build_target.sh "aarch64-apple-ios-sim" "aarch64-apple-ios-simulator"

with_android_sdk "aarch64-linux-android" ./build_target.sh "aarch64-linux-android" "aarch64-linux-android" || true
with_android_sdk "armv7a-linux-androideabi" ./build_target.sh "armv7-linux-androideabi" "armv7-linux-androideabi" || true
with_android_sdk "i686-linux-android" ./build_target.sh "i686-linux-android" "i686-linux-android" || true
with_android_sdk "x86_64-linux-android" ./build_target.sh "x86_64-linux-android" "x86_64-linux-android" || true

build_data
export_bundle
