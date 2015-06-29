@echo off

set rel_path=%~dp0%

rem // Save current directory and change to target directory
pushd %rel_path%

rem // Save value of CD variable (current directory)
set root=%rel_path%

rem // Restore original directory
popd

echo root: %root%

mkdir build
cd build

if "%1" == "" (
	set splinter_dir="../../../SPLINTER/SPLINTER/"
) else (
	set splinter_dir=%1
)

cmake %splinter_dir% -G "Visual Studio 12 2013"

msbuild.exe ALL_BUILD.vcxproj