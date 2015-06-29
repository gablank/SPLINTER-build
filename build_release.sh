#!/bin/bash

ROOT=$(pwd)

SPLINTER_DIR="../../SPLINTER/SPLINTER"
if [ $# -gt 0 ]; then
	SPLINTER_DIR=$1
fi

# If the path is not absolute, make it absolute
if [[ "$SPLINTER_DIR" != /* ]]; then
	SPLINTER_DIR="$(pwd)/$SPLINTER_DIR"
fi

mkdir $ROOT/build
cd $ROOT/build

function build {
	ARCH=$1
	if [ $ARCH = x86 ]; then
		BITNESS=32
	elif [ $ARCH = x86-64 ]; then
		BITNESS=64
	fi

	COMPILER=$2

	mkdir -p $ROOT/build/$COMPILER/$ARCH
	cd $ROOT/build/$COMPILER/$ARCH

	rm CMakeCache.txt
	echo "Building SPLINTER for $ARCH with $CXX"
	cmake $SPLINTER_DIR -DCMAKE_BUILD_TYPE=release -DARCH=$ARCH
	make -j$(nproc)
	make install
	cp libsplinter-1-4.so libsplinter-static-1-4.a "$ROOT/linux/$COMPILER/$ARCH"

	# Use GCC to generate the MatLab library
	if [ $COMPILER = "gcc" ]; then
		cp -r splinter-matlab $ROOT
	fi

	cd $ROOT/build
}


function compress {
	COMPILER=$1
	cd $ROOT/build
	zip -r "$ROOT/linux-$COMPILER$($CXX -dumpversion).zip" "$COMPILER/"
}


export CXX=$(which g++)
COMPILER=gcc
build x86 $COMPILER
build x86-64 $COMPILER
compress $COMPILER

export CXX=$(which clang++-3.5)
COMPILER=clang
build x86 $COMPILER
build x86-64 $COMPILER
compress $COMPILER
