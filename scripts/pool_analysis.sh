#!/bin/bash
# Characterize the slowdown of the 'pool' microbenchmark (design document,
# Section 5.5): is it caused by one of the two inlined fast paths, by the code
# itself, or by the block layout chosen after partial inlining?
#
#   ROOT=/work/out OUT=/work/results-pool ./pool_analysis.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
B=${BOLT_BIN:-/opt/bolt/bin}
ROOT=${ROOT:-/work/out}
OUT=${OUT:-/work/results-pool}
D=$ROOT/pool
SRC=${MICRO_SRC:-$HERE/../benchmarks/micro}
REST=(-reorder-functions=cdsort -split-functions -split-all-cold -split-eh -icf=1 -dyno-stats)
opt() { local o=$1; shift
  "$B/llvm-bolt" "$D/orig" -o "$D/$o" -data "$D/prof.fdata" "$@" > "$D/$o.log" 2>&1; }

# Only one of the two hot callees partially inlined.
opt pa-only-alloc -reorder-blocks=ext-tsp "${REST[@]}" -partial-inline -partial-inline-skip=pool_free
opt pa-only-free  -reorder-blocks=ext-tsp "${REST[@]}" -partial-inline -partial-inline-skip=pool_alloc
# Same transformation, different block layout.
opt pa-norb-bolt  "${REST[@]}"
opt pa-norb-pi    "${REST[@]}" -partial-inline
opt pa-cache-bolt -reorder-blocks=cache "${REST[@]}"
opt pa-cache-pi   -reorder-blocks=cache "${REST[@]}" -partial-inline
# The compiler inlining both callees (LTO), for reference.
tmp=$(mktemp -d)
cp -r "$SRC/pool" "$SRC/common.h" "$tmp/"
clang -O2 -flto -fuse-ld=lld "$tmp/pool/main.c" "$tmp/pool/lib.c" -o "$D/pa-lto"
rm -rf "$tmp"

stage=()
[ -n "${STAGE:-}" ] && stage=(--stage-dir "$STAGE")
python3 "$HERE/bench.py" --root "$ROOT" --out "$OUT" --only pool --rounds 15 "${stage[@]}" \
  --variants bolt,bolt-copy,bolt-pi,pa-only-alloc,pa-only-free,pa-norb-bolt,pa-norb-pi,pa-cache-bolt,pa-cache-pi,pa-lto
