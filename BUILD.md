# Lua Commander - Build from Source

## Build Requirements

To build from source you need CMake (available from http://www.cmake.org).
You need a platform with working compiler that supports LuaJIT 2.0+
(see http://luajit.org). For Linux and Mac OS X this should
be easy. For Windows the supported compiler is the Windows SDK command-line
tools based on Visual Studio 2010. The build also depends on PCRE
(documentation at http://pcre.org) which should be supported by all platforms.

## Linux and Mac OS X Build Instructions

Get a copy of the source. Create a build directory named `build`, it may
be inside your source directory of somewhere else. From `build` run
`cmake SOURCEDIR` giving the path to the source directory. Then run
`make`. To install locally you can do `sudo make install`. To build
distribution packages do `cpack`.

## Windows Build Instructions

First make sure you have either Visual Studio installed or the Microsoft
Windows SDK for Windows 7 (available at http://www.microsoft.com/en-us/download/details.aspx?id=8279).
You will also need to install the Microsoft Visual C++ 2010 Redistributable
package (available at http://www.microsoft.com/en-us/download/details.aspx?id=14632).
Install CMake (available at http://www.cmake.org).

Get a copy of the source. Create a build directory named `build`, either
inside your source tree or somewhere else. Using the Windows SDK Command
Prompt, run `setenv /release` to set the build environment to release mode.
If you are on x86_64 and would like to compile for x86 then do
`setenv /release /x86`. This should change the font from yellow to green.

If you are using the Windows SDK you will need
to copy `C:\Windows\System32\msvcr100.dll` to
`C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\Redist\x64\Microsoft.VC100.CRT\msvcr100.dll`
and copy `C:\Windows\SysWOW64\msvcr100.dll` to
`C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\Redist\x86\Microsoft.VC100.CRT\msvcr100.dll`

From the command prompt, navigate to `build` and run
`cmake -G"NMake Makefiles" -DCMAKE_BUILD_TYPE=Release SOURCEDIR`.
This will generate makefiles suitable for Microsoft's NMake tool.
Run `nmake` to do the build.

To build the binary Windows installer, install NSIS (available at 
http://nsis.sourceforge.net). Then run `cpack` from the `build`
directory to create the installer and zip archive.

## Cross Compile

The build includes limited cross-compile support. For POSIX builds
(Linux and Mac) it should be enough to set the environment variables
`CC` and `CROSSCC` to the alternate compiler. For example,
`export CC="gcc -m32" CROSSCC="gcc -m32"` can be used to setup
a 32-bit build on 64-bit systems. For exotic architectures check
that LuaJIT supports the architecture.

## Virtual Machine Builds

For reliable binary distribution on Linux multiple Vagrantfiles
are provided. Currently binary distributions are compiled on CentOS
5.6, the oldest distribution in common use. Point `Vagrantfile` to
a suitable file in `vagrantconf/`, then do `vagrant up`. This requires
VirtualBox and will download a copy of CentOS. Once started, you can
do `vagrant ssh` to connect. Navigate to `/vagrant` to get the project
source location and do a normal Linux build.

## Unit Testing

After building on POSIX systems, do `make unittest` to check functionality.
Unit testing is not currently supported for Windows.

## Linux Compatibility Testing

To check distribution compatibility of the resulting binary, use the
[Linux Application Checker](http://www.linuxfoundation.org/collaborate/workgroups/lsb/download).
