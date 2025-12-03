cd ../../../hw/vendor/riscv-dbg/tb/remote_bitbang
make clean
make all
cd -

#!/bin/bash
set -e

# Use C++ compiler (important!)
CXX=${CXX:-g++}

# Paths
SRC="../../../hw/vendor/lowrisc_opentitan/hw/dv/dpi/uartdpi/uartdpi.c"
OUT_LIB="uartdpi.so"

# Flags copied from the Makefile (C++ version)
CFLAGS_COMMON="-Wall -Wextra -Wno-missing-field-initializers \
               -Wno-unused-function -Wno-missing-braces \
               -O2 -g -march=native -DENABLE_LOGGING -DNDEBUG"

ALL_CFLAGS="-std=gnu++11 -fPIC ${CFLAGS_COMMON}"

# On most systems this is enough
LDFLAGS="-shared"

MODEL_TECH="/softs/mentor/qsta/2023.4/bin"
INCLUDES="-I${MODEL_TECH}/../include"

BUILD_DIR="./build"
mkdir -p ${BUILD_DIR}

echo "[INFO] Compiling (C++ mode like Makefile):"
echo "       SRC     = ${SRC}"
echo "       OUT_LIB = ${BUILD_DIR}/${OUT_LIB}"

${CXX} ${ALL_CFLAGS} ${INCLUDES} ${SRC} ${LDFLAGS} -o "${BUILD_DIR}/${OUT_LIB}"

echo "[INFO] Done."
echo "       Shared library: ${BUILD_DIR}/${OUT_LIB}"
echo
echo "[INFO] Use in ModelSim with:"
echo "       -sv_lib ${BUILD_DIR}/uartdpi"
