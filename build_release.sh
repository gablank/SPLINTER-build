#!/bin/bash

SPLINTER_MAJOR_VERSION=1
SPLINTER_MINOR_VERSION=4
SPLINTER_VERSION=$SPLINTER_MAJOR_VERSION-$SPLINTER_MINOR_VERSION

ROOT=$(pwd)
OS="unknown"
COMPILER="unknown"
NPROC="unknown"

# Defaults
SPLINTER_DIR="../../SPLINTER/SPLINTER"
MSBUILD_DIR="/C/Program Files (x86)/MSBuild/12.0/Bin"
VCVARSALL_DIR="/C/Program Files (x86)/Microsoft Visual Studio 12.0/VC"

# Capture the command argument for use in help messages
COMMAND=$0

# Thanks to http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#14203146
# for this great command line argument parsing algorithm
# Use > 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -m|--mingw-binary-dir)
    PATH="$2:$PATH"
    shift # past argument
    ;;
    -c|--cmake-binary-dir)
    PATH="$2:$PATH"
    shift # past argument
    ;;
	-vc|--vcvarsall-dir)
	VCVARSALL_DIR="$2"
	shift # past argument
	;;
	-mb|--msbuild-dir)
	MSBUILD_DIR="$2"
	shift # past argument
	;;
    *)
    # No preceding: path to SPLINTER
    SPLINTER_DIR=$1
    ;;
esac
shift # past argument or value
done

# Make sure SPLINTER_DIR is an absolute path
if [[ $SPLINTER_DIR != /* ]]; then
	SPLINTER_DIR="$(pwd)/$SPLINTER_DIR"
fi

# Check that we can find CMake
CMAKE_CMD=$(which cmake)
if [[ $CMAKE_CMD == "" ]]; then
	echo "Error: Can't find CMake, make sure it is in your PATH environment variable"
	echo "and try again!"
	echo "If you don't want to add CMake to your PATH, you can specify the path to it with"
	echo "$COMMAND -c /path/to/cmake/binary/directory"
	exit 1
fi

function update_commit_id {
	echo $(git -C "$SPLINTER_DIR" log -n 1 --pretty=format:"%H") > "$ROOT/$OS/$COMPILER/commit_id"
}

function update_compiler_version {
	echo $COMPILER_VERSION > "$ROOT/$OS/$COMPILER/compiler_version"
}

function build_gcc_clang {
	ARCH=$1
	COMPILER=$2

	mkdir -p $ROOT/$OS/$COMPILER/$ARCH
	mkdir -p $ROOT/build/$COMPILER/$ARCH
	cd $ROOT/build/$COMPILER/$ARCH
	
	rm CMakeCache.txt
	echo "Building SPLINTER for $ARCH with $CXX"
	"$CMAKE_CMD" "$SPLINTER_DIR" -DCMAKE_BUILD_TYPE=release -DARCH=$ARCH -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM="$MAKE_CMD"
	"$MAKE_CMD" -j$NPROC
}

function build_linux {
	echo "Building for Linux"
	OS=linux
	
	MAKE_CMD=$(which make)
	NPROC=$(nproc)
	
	GPP=$(which g++)
	if [[ $GPP != "" ]]; then
		export CXX=$GPP
		COMPILER=gcc
		COMPILER_VERSION=$($CXX -dumpversion)
		
		build_gcc_clang x86 $COMPILER
		cp libsplinter-$SPLINTER_VERSION.so libsplinter-static-$SPLINTER_VERSION.a "$ROOT/$OS/$COMPILER/$ARCH"
		"$MAKE_CMD" install
		cp -r splinter-matlab $ROOT
		
		build_gcc_clang x86-64 $COMPILER
		cp libsplinter-$SPLINTER_VERSION.so libsplinter-static-$SPLINTER_VERSION.a "$ROOT/$OS/$COMPILER/$ARCH"
		"$MAKE_CMD" install
		cp -r splinter-matlab $ROOT
		
		# Copy header files
		cp -r $SPLINTER_DIR/include $ROOT/$OS/$COMPILER/include
		cp -r $SPLINTER_DIR/thirdparty/Eigen $ROOT/$OS/$COMPILER/include
		
		# Write down the commit id this was compiled from
		update_commit_id
		update_compiler_version
	fi
	
	CLANG=$(which clang++-3.5)
	if [[ $CLANG != "" ]]; then
		export CXX=$CLANG
		COMPILER=clang
		COMPILER_VERSION=$($CXX -dumpversion)
		
		build_gcc_clang x86 $COMPILER
		cp libsplinter-$SPLINTER_VERSION.so libsplinter-static-$SPLINTER_VERSION.a "$ROOT/$OS/$COMPILER/$ARCH"
		
		build_gcc_clang x86-64 $COMPILER
		cp libsplinter-$SPLINTER_VERSION.so libsplinter-static-$SPLINTER_VERSION.a "$ROOT/$OS/$COMPILER/$ARCH"
		
		# Copy header files
		cp -r $SPLINTER_DIR/include $ROOT/$OS/$COMPILER/include
		cp -r $SPLINTER_DIR/thirdparty/Eigen $ROOT/$OS/$COMPILER/include
		
		# Write down the commit id this was compiled from
		update_commit_id
		update_compiler_version
	fi
}

# TODO: Avoid rebuilding every time?
function build_msvc {
	ARCH=$1
	COMPILER=$2
	
	mkdir -p $ROOT/$OS/$COMPILER/$ARCH
	mkdir -p $ROOT/build/$COMPILER/$ARCH
	cd $ROOT/build/$COMPILER/$ARCH
	
	# Need this so msbuild.exe can find the project file
#	export PATH="$ROOT/build/$COMPILER/$ARCH/:$PATH"
	rm CMakeCache.txt
	
	if [[ $ARCH == "x86" ]]; then
		cmd "/C vcvarsall.bat x86"
		GENERATOR="Visual Studio 12 2013"
	elif [[ $ARCH == "x86-64" ]]; then
		cmd "/C vcvarsall.bat x64"
		GENERATOR="Visual Studio 12 2013 Win64"
	else
		echo "Error: Unknown architecture given to build_msvc: $ARCH"
		exit 1
	fi
	
	"$CMAKE_CMD" $SPLINTER_DIR -DCMAKE_BUILD_TYPE=Release -DARCH=$ARCH -G "$GENERATOR"
	
	"$MSBUILD" ALL_BUILD.vcxproj -p:Configuration=Release -maxcpucount:$NPROC
	
	# Install
	mkdir -p "$ROOT/splinter-matlab/lib/$OS/$ARCH/"
	mkdir -p "$ROOT/$OS/$COMPILER/$ARCH"
	
	cp "Release/splinter-matlab-$SPLINTER_VERSION.dll" "$ROOT/splinter-matlab/lib/$OS/$ARCH/"
	cp "Release/splinter-$SPLINTER_VERSION.dll" "$ROOT/$OS/$COMPILER/$ARCH"
	cp "Release/splinter-static-$SPLINTER_VERSION.lib" "$ROOT/$OS/$COMPILER/$ARCH"
}

function build_windows {
	echo "Building for Windows"
	OS=windows
	
	export PATH="$MSBUILD_DIR:$PATH"
	export PATH="$VCVARSALL_DIR:$PATH"
	
	# Get number of processors for use with -maxcpucount
	NPROC_STRING=$(cmd "/C echo %NUMBER_OF_PROCESSORS%")
	NPROC="${NPROC_STRING//[!0-9]/}"
	
	# First build with MinGW if it is installed and in PATH
	GPP=$(which g++)
	MAKE_CMD=$(which mingw32-make)
	if [[ $GPP != "" && $MAKE_CMD != "" ]]; then
		export CXX=$GPP
		COMPILER=gcc
		COMPILER_VERSION=$($CXX -dumpversion)
		
		build_gcc_clang x86 $COMPILER
		cp libsplinter-$SPLINTER_VERSION.dll libsplinter-static-$SPLINTER_VERSION.a "$ROOT/$OS/$COMPILER/$ARCH"
		cp $SPLINTER_DIR/include -r 
		# Only x86 supported with GCC on Windows for now
#		build_gcc_clang x86-64 $COMPILER
		
		# Write down the commit id this was compiled from
		update_commit_id
		update_compiler_version
	fi

	MSBUILD=$(which msbuild.exe)
	if [[ $MSBUILD != "" ]]; then
		COMPILER=msvc
		COMPILER_VERSION=$(msbuild.exe "-version" | grep '^[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+$')
		
		build_msvc "x86" $COMPILER
		build_msvc "x86-64" $COMPILER
		
		# Write down the commit id this was compiled from
		update_commit_id
		update_compiler_version
	fi
}


mkdir -p $ROOT/build # -p to avoid error message when it already exists
cd $ROOT/build

#PLATFORM=$(uname)
if [[ $PLATFORM == MINGW* ]]; then
	build_windows
	
elif [[ $PLATFORM == Linux ]]; then
	build_linux
	
else
	echo "Unknown platform: $PLATFORM"
fi

cd $ROOT
# Check that all commit ids are the same
# If they are we can make a release
# TODO: Add osx
OSES="windows
linux"
COMMIT_ID=""
for os_dir in $OSES
do
	if [[ ! -d $os_dir ]]; then
		echo "Cannot make release because an OS directory ($os_dir) is missing."
		exit 1
	fi
	
	for compiler in $(ls $ROOT/$os_dir)
	do
		if [[ $COMMIT_ID == "" ]]; then
			COMMIT_ID=$(cat $ROOT/$os_dir/$compiler/commit_id)
		else
			if [[ $(cat $ROOT/$os_dir/$compiler/commit_id) != $COMMIT_ID ]]; then
				echo "Commit id mismatch, $os_dir/$compiler differs from previous."
				echo "Cannot make release."
				exit 1
			fi
		fi
	done
done

echo "All builds were built from the same commit, proceeding to make release."

# If tar is installed, and all commit ids are the same,
# then we make a release
TAR=$(which tar)
ZIP=$(which zip)
if [[ $TAR == ""  && $ZIP == "" ]]; then
	echo "Error: Neither tar nor zip is installed, cancelling release."
	exit 1
fi

mkdir -p $ROOT/releases
cd $ROOT/releases
for os_dir in $OSES
do
	for compiler in $(ls $ROOT/$os_dir)
	do
		files="x86 x86-64 include"
		compiler_version=$(cat $ROOT/$os_dir/$compiler/compiler_version)
		filename=$os_dir_$compiler$compiler_version
		$TAR -czf $filename.tar.gz
		$ZIP -czf $filename.tar.gz
	done
done