#!/bin/bash

SPLINTER_DIR="../../SPLINTER/SPLINTER"
if [ $# -gt 0 ]; then
	SPLINTER_DIR=$1
fi

# If the path is not absolute, make it absolute
if [[ "$SPLINTER_DIR" != /* ]]; then
	SPLINTER_DIR="$(pwd)/$SPLINTER_DIR"
fi

mkdir build
cd build

function build {
	ARCH=$1
	if [ $ARCH = x86 ]; then
		BITNESS=32
	elif [ $ARCH = x86-64 ]; then
		BITNESS=64
	fi

	COMPILER=$2

	rm -r *
	echo "Building SPLINTER for $ARCH with $CXX"
	cmake $SPLINTER_DIR -DCMAKE_BUILD_TYPE=release -DARCH=$ARCH
	make -j$(nproc)
	make install
	cp libsplinter-1-4.so libsplinter-static-1-4.a "../linux/$COMPILER/$ARCH"
	echo $($CXX -dumpversion) > "../linux/$COMPILER/compiler_version"
	if [ $COMPILER = "gcc" ]; then
		cp -r splinter-matlab ../
	fi
}


export CXX=$(which g++)
build x86 gcc
build x86-64 gcc

export CXX=$(which clang++-3.5)
build x86 clang
build x86-64 clang
