#!/bin/bash
# Build the clang workload: clang at the pinned LLVM commit (without the
# patch), with the settings of clang/cmake/caches/BOLT.cmake, i.e. the in-tree
# Clang-BOLT rules: Release, host target only, -Wl,--emit-relocs,-znow.
# ClangIR is disabled: it is on by default, needs MLIR, and is only used with
# -fclangir, not for normal C/C++ compilation. Runs in the builder stage of
# docker/Dockerfile:
#
#   SRC=/llvm/src OUT=/opt/clang-workload BUILD=/llvm/build-clang ./build.sh
#
# Installs into $OUT (copied to /work/rw/clang in the evaluation image):
#   bin/clang-<major>, bin/clang   the compiler (bin/ is also where the
#                                  instrumented clang is placed for training)
#   lib/clang/<major>/             its resource headers
#   src/                           the sources the training compiles: LLVM,
#                                  cmake/, third-party/, libc/ (whose headers
#                                  LLVMSupport includes), without tests, and
#                                  perf-training/cxx/hello_world.cpp
#   inputs/, compile.sh, icount-cmd.json   timing inputs (prepare_inputs.py)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:-/llvm/src}
OUT=${OUT:-/opt/clang-workload}
B=${BUILD:-/llvm/build-clang}

cmake -G Ninja -S "$SRC/llvm" -B "$B" -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TARGETS_TO_BUILD=Native \
  -DCLANG_ENABLE_CIR=OFF \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--emit-relocs,-znow" \
  -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--emit-relocs,-znow" \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld \
  -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_DOCS=OFF
ninja -C "$B" clang clang-resource-headers

major=$("$B/bin/clang" -dumpversion | cut -d. -f1)
rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib/clang" "$OUT/src"
cp "$(readlink -f "$B/bin/clang")" "$OUT/bin/clang-$major"
ln -s "clang-$major" "$OUT/bin/clang"
cp -r "$B/lib/clang/$major" "$OUT/lib/clang/"

# Sources of the training (clang/utils/perf-training).
mkdir -p "$OUT/src/clang/utils/perf-training/cxx"
cp "$SRC/clang/utils/perf-training/cxx/hello_world.cpp" \
  "$OUT/src/clang/utils/perf-training/cxx/"
tar -C "$SRC" --exclude=llvm/test --exclude=libc/test -cf - llvm cmake third-party libc \
  | tar -C "$OUT/src" -xf -

python3 -I "$HERE/prepare_inputs.py" "$SRC" "$B" "$OUT" /work/rw/clang
