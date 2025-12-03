#!/bin/bash
set -e

# Set compiler and paths
CXX=${CXX:-g++}
SRC="../../../target/sim/src/elfloader.cpp"
OUT_LIB="libelfloader.so"
CXXFLAGS="-fPIC -std=c++11 -g"
LDFLAGS="-shared"
MODEL_TECH="/softs/mentor/qsta/2023.4/bin"  # adjust if needed
INCLUDES="-I${MODEL_TECH}/../include"
BUILD_DIR="./build"

# Make build directory
mkdir -p ${BUILD_DIR}

# Compile to shared library
echo "[INFO] Compiling ${SRC} -> ${BUILD_DIR}/${OUT_LIB}"
${CXX} ${CXXFLAGS} ${INCLUDES} ${SRC} ${LDFLAGS} -o ${BUILD_DIR}/${OUT_LIB}

echo "[INFO] Done. Output: ${BUILD_DIR}/${OUT_LIB}"
echo "[INFO] You can now include it in ModelSim with:"
echo "       -sv_lib ${BUILD_DIR}/libelfloader"
