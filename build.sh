#!/bin/bash

APACHE_ZIP="https://www.apachelounge.com/download/VS16/binaries/httpd-2.4.46-win32-VS16.zip"
PHP_ZIP="https://windows.php.net/downloads/releases/php-7.4.12-Win32-vc15-x86.zip"
VC_EXE="https://aka.ms/vs/16/release/VC_redist.x86.exe"

APACHE_MODULES="access_compat authz_core dir env log_config mime rewrite setenvif"
PHP_EXTENSIONS="bz2 gd2 ldap mbstring opcache openssl pdo_sqlite"

# Try to identify the DLLs that the given binary needs and copy them from
# the VC redistributable and the binary's own folder. Check dpendencies of
# the found DLLs recursively
function copyruntimelibs() {
    local SRC   # the binary to check
    local SELF  # path of the binary
    local PSELF # parent path of the binary
    local DLL   # a found dependency
    local LC    # the dependency lowercased
    local LLC   # the dpendency with underscores instead of hyphens
    local ORG   # path to the matching DLL file

    SRC=$1
    SELF=$(dirname "$SRC")

    for DLL in $(objdump --private-headers "$SRC" |grep 'DLL Name'|awk '{print $3}'); do
        LC=$(echo "$DLL" | tr '[:upper:]' '[:lower:]')
        LLC=$(echo "$LC" | tr '-' '_')
        PSELF="$SELF/.."

        for ORG in "$SELF/$DLL" "$PSELF/$DLL" "tmp/vc/$LC" "tmp/vc/$LLC"; do
            if [ -e "$ORG" ]; then
                if [ ! -e "out/server/$DLL" ]; then
                    # copy the DLL
                    cp -v "$ORG" "out/server/$DLL"
                    # check dependencies for the DLL
                    copyruntimelibs "$ORG"
                fi
            fi
        done
    done
}

# an up-to-date upx is preferable now that development has started again
if [ ! -e "./upx" ]; then
    echo "Please place an up-to-date upx binary in this directory"
    echo "See https://github.com/upx/upx/releases/"
    exit
fi

if ! command -v cabextract >/dev/null 2>&1; then
    echo "Please install the cabextract utility"
    exit
fi

if ! command -v objdump >/dev/null 2>&1; then
    echo "Please install the objdump utility"
    exit
fi


# we use previously downloaded files, but we warn about it
if [ -d "tmp" ]; then
    echo "WARNING: tmp exist, previous downloads will be used. Abort and delete tmp for fresh sources."
    read
fi

# clean up
if [ -d "out" ]; then
    rm -rf "out"
fi

# create folders
mkdir -p tmp
mkdir -p out
mkdir -p out/server
mkdir -p out/server/modules
mkdir -p out/server/php
mkdir -p out/server/php/ext

# copy default configs
cp -r tpl/* out/

# download and unpack Apache, PHP and the Visual Studio Redistributable
if [ ! -f "tmp/apache.zip" ]; then
    wget --user-agent="" "$APACHE_ZIP" -O tmp/apache.zip
fi
if [ ! -f "tmp/php.zip" ]; then
    wget "$PHP_ZIP" -O tmp/php.zip
fi
if [ ! -f "tmp/vc.exe" ]; then
    wget "$VC_EXE" -O tmp/vc.exe
fi

# delete old unpacks
if [ -d "tmp/apache" ]; then
    rm -rf tmp/apache
fi
if [ -d "tmp/php" ]; then
    rm -rf tmp/php
fi
if [ -d "tmp/vc" ]; then
    rm -rf tmp/vc
fi

# unpack sources
cd tmp || exit
    unzip apache.zip
    mv Apache[0-9][0-9] apache
    rm -f ReadMe.txt
    rm -f -- --*

    mkdir php
    cd php || exit
    unzip ../php.zip
    cd ..

    mkdir vc
    cd vc || exit
    cabextract -L ../vc.exe
    cabextract -L *
    cd ..
cd ..

# copy Apache
cp tmp/apache/LICENSE.txt                   out/server/apache-license.txt
cp tmp/apache/bin/httpd.exe                 out/server/mapache.exe
copyruntimelibs tmp/apache/bin/httpd.exe
for MOD in $APACHE_MODULES; do
    cp "tmp/apache/modules/mod_$MOD.so" "out/server/modules/"
    copyruntimelibs "tmp/apache/modules/mod_$MOD.so"
done

# copy PHP
cp tmp/php/license.txt                      out/server/php/php-license.txt
cp tmp/php/php7apache2_4.dll                out/server/php/
copyruntimelibs tmp/php/php7apache2_4.dll
for EXT in $PHP_EXTENSIONS; do
    cp "tmp/php/ext/php_$EXT.dll" "out/server/php/ext/"
    copyruntimelibs "tmp/php/ext/php_$EXT.dll"
done

# compress files
./upx out/server/*.dll
./upx out/server/*.exe
./upx out/server/modules/*.so
ls out/server/php/ext/* | grep -vE 'mbstring|opcache' | xargs ./upx

