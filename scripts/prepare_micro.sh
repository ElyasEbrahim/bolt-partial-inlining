#!/bin/bash
# Build the microbenchmarks and all their BOLT variants into $ROOT/<name>.
# Training inputs are 10x smaller than the evaluation inputs in workloads.py.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${MICRO_SRC:-$HERE/../benchmarks/micro}
ROOT=${ROOT:-/work/out}
BUILD=${BUILD:-/work/micro-build}
rm -rf "$BUILD" && mkdir -p "$BUILD" && cp -r "$SRC"/. "$BUILD"/
make -s -C "$BUILD" clean all CC=${CC:-clang}
v() { "$HERE/bolt_variants.sh" "$BUILD/$1/$1.exe" "$ROOT/$2" "${@:3}"; }
v bufwrite bufwrite     @BIN@ 30000000
v memo     memo         @BIN@ 20000000 20
v trace    trace        @BIN@ 30000000
v pool     pool         @BIN@ 20000000
v mixed    mixed        @BIN@ 6000000
v memo     memo-lowhit  @BIN@ 6000000 700
v unsafe   unsafe       @BIN@ 20000000
v compute  compute      @BIN@ 4
