#!/bin/bash

UPX_VER=4.1.0
UPX_TAR="https://github.com/upx/upx/releases/download/v${UPX_VER}/upx-${UPX_VER}-amd64_linux.tar.xz"

# download upx
if [ ! -e "./upx" ]; then
    if [ ! -f "tmp/upx.tar.xz" ]; then
        wget "$UPX_TAR" -O tmp/upx.tar.xz
    fi
    if [ -d "tmp/upx" ]; then
        rm -rf tmp/upx
    fi
    cd tmp || exit
        tar -xf upx.tar.xz --strip-components=1 upx-$UPX_VER-amd64_linux/upx
        cp upx ..
        chmod 755 ../upx
    cd ..
fi

if [ $(./upx -V |head -n 1|cut -c 5) != 4 ]; then
    echo "UPX version >=4 is needed."
    echo "See https://github.com/upx/upx/releases/latest"
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

