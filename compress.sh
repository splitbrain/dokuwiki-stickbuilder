#!/bin/bash

UPX_ZIP="https://nightly.link/upx/upx/workflows/ci/devel/amd64-linux-gcc-10.zip"

# download upx
if [ ! -e "./upx" ]; then
    if [ ! -f "tmp/upx.zip" ]; then
        wget "$UPX_ZIP" -O tmp/upx.zip
    fi
    if [ -d "tmp/upx" ]; then
        rm -rf tmp/upx
    fi
    cd tmp || exit
        unzip upx.zip
        cp upx ..
        chmod 755 ../upx
    cd ..
fi

if [ $(./upx -V |head -n 1|cut -c 5) != 4 ]; then
    echo "Version 4 of UPX is needed. You probably need a devel release"
    echo "See https://github.com/upx/upx/actions"
    exit 1
fi

if [ ! -d "out" ]; then
    echo "out directory not found. run build.sh first"
    exit 1
fi

# compress files
./upx out/server/*.dll
./upx out/server/*.exe
./upx out/server/modules/*.so
./upx out/server/php/ext/*

exit 0

