#! /bin/sh

set -eu

cross_tuple=arm-cortex_a8-linux-gnueabihf

export CC="${HOME}/ct-ng/x-tools/${cross_tuple}/bin/${cross_tuple}-gcc"
export DESTDIR=$($CC -print-sysroot)

sqlite_url=https://www.sqlite.org/2024/sqlite-autoconf-3450200.tar.gz

curl "$sqlite_url" | tar -xz
cd sqlite-autoconf-3450200

# These commands use CC and DESTDIR in the environment
./configure --prefix=/usr --host="$cross_tuple"
make install



