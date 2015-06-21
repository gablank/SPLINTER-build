#!/bin/bash

SPLINTER_DIR="../../SPLINTER/SPLINTER"
if [ $# -gt 0 ]; then
	SPLINTER_DIR=$1
fi

mkdir build
cd build

function build {
	INSTRUCTION_SET=$1
	if [ $INSTRUCTION_SET = x86 ]; then
		BITNESS=32
	elif [ $INSTRUCTION_SET = x64 ]; then
		BITNESS=64
	fi

	rm -r *
	echo "Building SPLINTER for $INSTRUCTION_SET with $CXX"
	cmake "../$SPLINTER_DIR" -DCMAKE_BUILD_TYPE=release -DBITNESS=$BITNESS
	make -j4
	make install
	cp libsplinter-1-4.so libsplinter-static-1-4.a "../$CXX/$INSTRUCTION_SET"
}

function compress {
	TARGET_FILE=$1
}

export CXX=$(which g++)
build x86
build x64

export CXX=$(which clang++-3.5)
build x86
build x64
