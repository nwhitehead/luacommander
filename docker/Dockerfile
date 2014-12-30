FROM debian:6
MAINTAINER Nathan Whitehead <nwhitehe@gmail.com>

# Required packages
RUN apt-get update && apt-get install -y \
    git \
    g++ \
    make \
    curl

# Install new version of CMake
RUN mkdir -p /usr/src \
    && curl http://www.cmake.org/files/v3.1/cmake-3.1.0-Linux-x86_64.tar.gz \
    | tar -xzC /usr/src \
    && cp -r /usr/src/cmake-3.1.0-Linux-x86_64/* /usr
