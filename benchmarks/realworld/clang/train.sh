#!/bin/bash
# Training run of the clang workload, as in the in-tree Clang-BOLT rules
# (clang/utils/perf-training, CLANG_BOLT=INSTRUMENT): compile
# cxx/hello_world.cpp twice (cxx/hello_world.cpp's RUN lines), then configure
# LLVM with the clang under training and build LLVMSupport in Release mode
# (llvm-support/build.test). The image does not contain LLVM's tests, so the
# configuration sets LLVM_INCLUDE_TESTS=OFF. The working directory is fixed
# so that the paths the compiler sees are the same in every run.
#
#   train.sh <clang>     (scripts/prepare_realworld.sh, via bolt_variants.sh)
set -euo pipefail
# prepare_realworld.sh exports PYTHONHOME for the CPython workload; CMake runs
# the system Python, which does not start with it.
unset PYTHONHOME
C=$1
SRC=${CLANG_SRC:-/work/rw/clang/src}
T=${CLANG_TRAIN_DIR:-/work/clang-train}
rm -rf "$T"; mkdir -p "$T"; cd "$T"
"$C" --driver-mode=g++ -c "$SRC/clang/utils/perf-training/cxx/hello_world.cpp"
"$C" --driver-mode=g++ -Wall -pedantic -c "$SRC/clang/utils/perf-training/cxx/hello_world.cpp"
cmake -G Ninja -DCMAKE_MAKE_PROGRAM=ninja -B "$T/support" -S "$SRC/llvm" \
  -DCMAKE_C_COMPILER="$C" "-DCMAKE_CXX_COMPILER=$C;--driver-mode=g++" \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF > "$T/configure.log"
cmake --build "$T/support" -v --target LLVMSupport > "$T/build.log"
