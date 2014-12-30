#!/bin/bash

set -e

# Get user configuration from file
URL="https://github.com/nwhitehead/luacommander.git"
BUILD_COMMAND="mkdir -p /root/build && cd /root/build && export CC= && export CROSSCC= && cmake /root/project && make && cpack"
BUILD32_COMMAND="mkdir -p /root/build && cd /root/build && export CC=\"gcc -m32\" && export CROSSCC=\"gcc -m32\" && cmake /root/project && make && cpack"
# BUG - aufs has problems actually deleting this directory, so delete contents
CLEAN_COMMAND="rm -fr /root/build/*"
NAME="luacmd"
GET_COMMAND="cd /root/build && tar cO *.zip | gzip -f"

COMMAND=$1

# Store files to indicate which tags are used in docker
mkdir -p .tags

# Make sure environment base image is setup
docker build -t nwhitehead/build .

if [ "$COMMAND" = "" ];
then
    if [ -e .tags/$NAME-latest ];
    then
        # File exists, that means we are in a ready state to do incremental build
        # Run the build command
        echo $BUILD_COMMAND
        echo "You may need to remove the cid file if this fails"
        docker run --cidfile="cid" -a stdout -a stdin $NAME/latest /bin/sh -c "$BUILD_COMMAND"
        # Commit changes
        docker commit `cat cid` $NAME/latest
        rm cid
        echo "BUILD SUCCEEDED"
    else
        # Checkout the code, create container
        docker run --cidfile="cid" -a stdout -t nwhitehead/build git clone $URL /root/project

        # Commit checkout state, set to be latest state
        docker commit `cat cid` $NAME/checkout
        touch .tags/$NAME-checkout
        docker commit `cat cid` $NAME/latest
        touch .tags/$NAME-latest
        rm cid
        echo "CHECKOUT SUCCEEDED"
    fi
else
    echo "COMMAND " $COMMAND
    if [ "$COMMAND" = "get" ];
    then
        echo "GETTING"
        docker run $NAME/latest /bin/sh -c "$GET_COMMAND" > result.tar.gz
        echo "RESULTS ARE IN result.tar.gz"
        exit 0
    fi
    if [ "$COMMAND" = "pull" ];
    then
        echo "PULLING"
        echo "You may need to remove the cid file if this fails"
        docker run --cidfile="cid" -a stdout -a stdin $NAME/latest /bin/sh -c "cd /root/project; git pull"
        # Commit changes
        docker commit `cat cid` $NAME/latest
        rm cid
        echo "GIT PULLED"
        exit 0
    fi
    if [ "$COMMAND" = "build32" ];
    then
        echo "BUILDING FOR 32BIT"
        # Run the build command
        echo $BUILD32_COMMAND
        echo "You may need to remove the cid file if this fails"
        docker run --cidfile="cid" -a stdout -a stdin $NAME/latest /bin/sh -c "$BUILD32_COMMAND"
        # Commit changes
        docker commit `cat cid` $NAME/latest
        rm cid
        echo "BUILD SUCCEEDED"
    fi
    if [ "$COMMAND" = "clean" ];
    then
        echo "CLEANING BUILD"
        # Run the build command
        echo $CLEAN_COMMAND
        echo "You may need to remove the cid file if this fails"
        docker run --cidfile="cid" -a stdout -a stdin $NAME/latest /bin/sh -c "$CLEAN_COMMAND"
        # Commit changes
        docker commit `cat cid` $NAME/latest
        echo "$NAME/latest -> `cat cid`"
        rm cid
        echo "CLEAN SUCCEEDED"
    fi
fi
