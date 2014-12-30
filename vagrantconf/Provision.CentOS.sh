#!/usr/bin/env bash

# Get new version of CMake
wget http://www.cmake.org/files/v3.1/cmake-3.1.0-Linux-i386.tar.gz
tar xvfz cmake-3.1.0-Linux-i386.tar.gz
cp -r cmake-3.1.0-Linux-i386/* /usr

# Need C++ for CMake detection
yum install -y gcc-c++
