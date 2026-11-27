#!/bin/bash
# Build all BOLT variants of the real-world workloads into $ROOT/<name>.
# Training inputs differ from (and are smaller than) the evaluation inputs
# defined in workloads.py.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RW=${RW:-/work/rw}
ROOT=${ROOT:-/work/out}
WL=${WL:-$HERE/../benchmarks/realworld}
V="$HERE/bolt_variants.sh"
# Also the baseline and the pass with the previous AArch64 branch relaxation
# (bolt-nocl, bolt-pi-nocl; see bolt_variants.sh).
export RELAX_LEGACY=1
# Same environment as the evaluation runs in workloads.py.
export PYTHONHOME=$RW/cpython/inst PYTHONHASHSEED=0

# Corpora for zstd: train on C sources, evaluate on Python sources.
mkdir -p "$RW/corpus"
( cd "$RW/cpython/build" && find Modules Objects Python -name '*.c' | sort | xargs cat ) > "$RW/corpus/train.txt"
( cd "$RW/cpython/build" && find Lib -name '*.py' | sort | xargs cat ) > "$RW/corpus/eval.txt"
"$RW/zstd/zstd" -q -3 -f "$RW/corpus/eval.txt" -o "$RW/corpus/eval.txt.zst"
# Larger evaluation inputs so that each run takes a few hundred milliseconds.
for _ in 1 2 3 4; do cat "$RW/corpus/eval.txt"; done > "$RW/corpus/eval4.txt"
for _ in 1 2 3 4; do cat "$RW/corpus/eval4.txt"; done > "$RW/corpus/eval16.txt"
"$RW/zstd/zstd" -q -3 -f "$RW/corpus/eval16.txt" -o "$RW/corpus/eval16.txt.zst"
rm -f "$RW/corpus/eval16.txt"
"$RW/zstd/zstd" -q -3 -f "$RW/corpus/train.txt" -o "$RW/corpus/train.txt.zst"
# Documents for jq and libxml2: training, evaluation (larger) and the small
# inputs of the instruction counts.
for k in "json train 60000" "json eval 160000" "json icount 15000" \
         "xml train 60000" "xml eval 240000" "xml icount 15000"; do
  read -r fmt use n <<< "$k"
  python3 -I "$WL/datagen.py" "$fmt" "$n" > "$RW/corpus/data-$use.$fmt"
done

sel=("$@"); [ ${#sel[@]} -gt 0 ] || sel=(sqlite lua cpython zstd jq libxml2 clang)
for w in "${sel[@]}"; do
  echo "== $w"
  case $w in
  sqlite)  "$V" "$RW/sqlite/speedtest1" "$ROOT/sqlite" @BIN@ --size 20 --memdb ;;
  lua)     "$V" "$RW/lua/lua" "$ROOT/lua" @BIN@ "$WL/lua/bench.lua" 2 ;;
  cpython) "$V" "$RW/cpython/python" "$ROOT/cpython" @BIN@ -S "$WL/python/bench.py" 2 ;;
  # Two training processes (compression, decompression). Each writes its own
  # profile, and the profiles are merged: with a single profile file the
  # decompression run would overwrite the profile of the compression run
  # (versions up to 1.3.1 had this bug; compression had no profile).
  zstd)    APPEND_PID=1 "$V" "$RW/zstd/zstd" "$ROOT/zstd" sh -c \
             "@BIN@ -q -3 -c $RW/corpus/train.txt > /dev/null && @BIN@ -q -d -c $RW/corpus/train.txt.zst > /dev/null" ;;
  # bolt-pi-skip: partial inlining without the trivial callee jv_get_kind (one
  # instruction), which BOLT's existing -inline-all also inlines.
  jq)      PI_SKIP=jv_get_kind "$V" "$RW/jq/jq" "$ROOT/jq" @BIN@ -f "$WL/jq/bench.jq" \
             "$RW/corpus/data-train.json" ;;
  libxml2) "$V" "$RW/libxml2/xmllint" "$ROOT/libxml2" @BIN@ --noout \
             --xpath "count(//item[@kind='b'])" "$RW/corpus/data-train.xml" ;;
  clang)
    # Timing input (see benchmarks/realworld/clang): the SQLite amalgamation,
    # preprocessed by the original clang.
    "$RW/clang/bin/clang" -E "$RW/sqlite/build/sqlite-amalgamation-3540100/sqlite3.c" \
      -o "$RW/clang/inputs/sqlite3.i"
    # The in-tree Clang-BOLT rules: the instrumented clang next to clang (it
    # finds its resource headers there), one profile per process, and the
    # options of perf-helper.py bolt-optimize (clang/utils/perf-training).
    layout="-reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions"
    layout+=" -split-all-cold -split-eh -dyno-stats -use-gnu-stack -update-debug-sections"
    INSTR="$RW/clang/bin/clang-bolt.inst" APPEND_PID=1 BOLT_LAYOUT="$layout" \
      "$V" "$(readlink -f "$RW/clang/bin/clang")" "$ROOT/clang" \
      bash "$WL/clang/train.sh" @BIN@ ;;
  esac
done
