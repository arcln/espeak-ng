#! /usr/bin/env bash

set -e
cd $(dirname $0)

function clean_workspace {
	git clean -fdx -e build/bundle $(dirname $0)
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
	docker run --rm -t -v $(pwd):/src -w /src --entrypoint bash --platform linux/amd64 "ghcr.io/cross-rs/$1:main" -- ./build_target.sh "$1" "$2" "x86_64-unknown-linux-gnu"
}

function build_data {
	clean_workspace

	./configure \
		--without-speechplayer \
		--without-sonic \
		--without-pcaudiolib \
		LDFLAGS="-lpthread"

	make -j 16 src/espeak-ng
	make

	cp -r espeak-ng-data build/bundle
	rm -rf build/bundle/espeak-ng-data/mbrola_ph build/bundle/espeak-ng-data/voices
}

function export_bundle {
	cd build/bundle
	zip -r ../libespeak-ng.zip .
	cd -
}

function stuff_without_lpthread {
	build_data
	clean_workspace

	./build_target.sh "aarch64-apple-darwin" "aarch64-apple-darwin" "aarch64-apple-darwin"
	with_xcode_sdk "iphoneos" ./build_target.sh "aarch64-apple-ios" "aarch64-apple-ios" "aarch64-apple-darwin"
	with_xcode_sdk "iphonesimulator" ./build_target.sh "aarch64-apple-ios-sim" "aarch64-apple-ios-simulator" "aarch64-apple-darwin"

	build_in_docker "x86_64-linux-android" "x86_64-linux-android"
	build_in_docker "i686-linux-android" "i686-linux-android"
	build_in_docker "aarch64-linux-android" "aarch64-linux-android"
	build_in_docker "armv7-linux-androideabi" "armv7a-linux-androideabi"
}

function stuff_with_lpthread {
	build_in_docker "x86_64-unknown-linux-gnu" "x86_64-unknown-linux-gnu"

	export_bundle
}

stuff_without_lpthread

# this will not work "as-is" because of missing -lpthread in Makefile.am
# TODO: automate this
# for now need to manually add -lpthread in Makefile.am and run this part
# stuff_with_lpthread
