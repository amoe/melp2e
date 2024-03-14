# XXX this should really be a makefile now...

CC="${HOME}/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-gcc"
AR="${HOME}/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-ar"
READELF="${HOME}/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-readelf"

BUILD_DIR=build

"$CC" -c -o "${BUILD_DIR}/test1.o" test1.c
"$CC" -c -o "${BUILD_DIR}/test2.o" test2.c

OBJECTS="${BUILD_DIR}/test1.o ${BUILD_DIR}/test2.o"

"$AR" rc "${BUILD_DIR}/libtest.a" $OBJECTS
"$CC" -shared -o "${BUILD_DIR}/libtest.so" $OBJECTS

"$CC" -I. -L"$BUILD_DIR" -o "${BUILD_DIR}/helloworld" -ltest helloworld.c

"$READELF" -a "${BUILD_DIR}/helloworld" | grep "Requesting program interpreter:"
"$READELF" -a "${BUILD_DIR}/helloworld" | grep NEEDED
