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

sel=("$@"); [ ${#sel[@]} -gt 0 ] || sel=(sqlite lua cpython zstd)
for w in "${sel[@]}"; do
  echo "== $w"
  case $w in
  sqlite)  "$V" "$RW/sqlite/speedtest1" "$ROOT/sqlite" @BIN@ --size 20 --memdb ;;
  lua)     "$V" "$RW/lua/lua" "$ROOT/lua" @BIN@ "$WL/lua/bench.lua" 2 ;;
  cpython) "$V" "$RW/cpython/python" "$ROOT/cpython" @BIN@ -S "$WL/python/bench.py" 2 ;;
  zstd)    "$V" "$RW/zstd/zstd" "$ROOT/zstd" sh -c \
             "@BIN@ -q -3 -c $RW/corpus/train.txt > /dev/null && @BIN@ -q -d -c $RW/corpus/train.txt.zst > /dev/null" ;;
  esac
done
