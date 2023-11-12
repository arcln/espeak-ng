#! /usr/bin/env bash

set -e
cd $(dirname $0)

function clean_workspace {
	make distclean || true
	./autogen.sh
}

function with_xcode_sdk {
	CC="xcrun -sdk $1 clang -arch arm64" \
	CXX="xcrun -sdk $1 clang++ -arch arm64" \
	LD="xcrun -sdk $1 ld" \
	AR="xcrun -sdk $1 ar" \
	RANLIB="xcrun -sdk $1 ranlib" \
	${@:2}
}

function build_in_docker {
	clean_workspace
	docker run --rm -t -v $(pwd):/src -w /src --entrypoint bash --platform linux/amd64 "ghcr.io/cross-rs/$1:main" -- ./build_target.sh "$1" "$1" "x86_64-unknown-linux-gnu"
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

git clean -fdx

clean_workspace
./build_target.sh "aarch64-apple-darwin" "aarch64-apple-darwin" "aarch64-apple-darwin"
with_xcode_sdk "iphoneos" ./build_target.sh "aarch64-apple-ios" "aarch64-apple-ios" "aarch64-apple-darwin"
with_xcode_sdk "iphonesimulator" ./build_target.sh "aarch64-apple-ios-sim" "aarch64-apple-ios-simulator" "aarch64-apple-darwin"

build_in_docker "x86_64-linux-android"
build_in_docker "i686-linux-android"
build_in_docker "aarch64-linux-android"
build_in_docker "armv7-linux-androideabi"
build_in_docker "x86_64-unknown-linux-gnu"

build_data
export_bundle
