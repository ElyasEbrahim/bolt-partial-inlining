#!/bin/bash
# Why is the 'pool' microbenchmark slower with partial inlining? (design
# document, Section 5.5). Four experiments, timed like the main evaluation
# (bench.py: interleaved rounds, every run from a fresh copy at one path,
# output of every run verified); speedups are relative to 'bolt':
#
#   layout/     BOLT outputs: only one of the two callees partially inlined,
#               other block orders, the compiler's LTO build; and hand-written
#               loops that mirror four of them (hw-*, see pool_loop.py), which
#               must run as fast as the BOLT output they mirror
#   distance/   the partially inlined loop with instructions added or removed
#               between the two inlined regions, and with reloads replaced by
#               register copies
#   placement/  the call-based and the partially inlined loop, each shifted
#               to 16 code placements
#   counter/    BOLT outputs and hand-written loops for a build whose loop
#               computes slot = i & (w - 1) instead of slot = rng % w. The
#               random number generator is a loop-carried dependency of its
#               own that bounds the iteration time of the published
#               benchmark from below; without it the loop is bound by the
#               pool's memory only.
#
#   ROOT=/work/out OUT=/work/results/pool-analysis [STAGE=/stage] ./pool_analysis.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
B=${BOLT_BIN:-/opt/bolt/bin}
ROOT=${ROOT:-/work/out}
OUT=${OUT:-/work/results-pool}
ROUNDS=${POOL_ROUNDS:-15}
SRC=${MICRO_SRC:-$HERE/../benchmarks/micro}
REST=(-reorder-functions=cdsort -split-functions -split-all-cold -split-eh -icf=1 -dyno-stats)
stage=()
[ -n "${STAGE:-}" ] && stage=(--stage-dir "$STAGE")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# BOLT variants of <dir>/orig with other block orders, and the LTO build of
# the sources in <src>.
bolt_layouts() { local d=$1 src=$2
  opt() { local o=$1; shift
    "$B/llvm-bolt" "$d/orig" -o "$d/$o" -data "$d/prof.fdata" "$@" > "$d/$o.log" 2>&1; }
  # Only one of the two hot callees partially inlined.
  opt pa-only-alloc -reorder-blocks=ext-tsp "${REST[@]}" -partial-inline -partial-inline-skip=pool_free
  opt pa-only-free  -reorder-blocks=ext-tsp "${REST[@]}" -partial-inline -partial-inline-skip=pool_alloc
  # Same transformation, different block layout.
  opt pa-norb-bolt  "${REST[@]}"
  opt pa-norb-pi    "${REST[@]}" -partial-inline
  opt pa-cache-bolt -reorder-blocks=cache "${REST[@]}"
  opt pa-cache-pi   -reorder-blocks=cache "${REST[@]}" -partial-inline
  # The compiler inlining both callees (LTO), for reference.
  clang -O2 -flto -fuse-ld=lld "$src/pool/main.c" "$src/pool/lib.c" -o "$d/pa-lto"
}

# Assemble the hand-written loops into <dir>/hw-*; prints their names.
hand_written() { local d=$1; shift
  local s="$tmp/hw.$RANDOM" names n
  names=$(python3 "$HERE/pool_loop.py" "$s" "$@")
  clang -O2 -g0 -c "$SRC/pool/lib.c" -o "$s/lib.o"
  for n in $names; do
    clang -c "$s/$n.s" -o "$s/$n.o"
    clang "$s/$n.o" "$s/lib.o" -o "$d/$n" -fuse-ld=lld
  done
  echo "$names"
}
bench() { local root=$1 out=$2 rounds=$3 variants=$4
  mkdir -p "$out"
  python3 "$HERE/bench.py" --root "$root" --out "$out" --only pool \
    --rounds "$rounds" "${stage[@]}" --variants "$variants"; }
csv() { local IFS=,; echo "$*"; }

# ---- published benchmark ----------------------------------------------------
D=$ROOT/pool
cp -r "$SRC/pool" "$SRC/common.h" "$SRC/Makefile" "$tmp/"
bolt_layouts "$D" "$tmp"
hand_written "$D" > /dev/null
read -r -a PLACED <<< "$(hand_written "$D" --placement)"

bench "$ROOT" "$OUT/layout" "$ROUNDS" \
  bolt,bolt-copy,bolt-pi,pa-only-alloc,pa-only-free,pa-norb-bolt,pa-norb-pi,pa-cache-bolt,pa-cache-pi,pa-lto,hw-base,hw-straight,hw-norb,hw-cache
bench "$ROOT" "$OUT/distance" "$ROUNDS" \
  bolt,hw-base,hw-base-head+1,hw-short2,hw-short1,hw-samebase,hw-straight,hw-gap+1,hw-gap+2,hw-gap+3,hw-gap+4,hw-gap+5,hw-gap+6,hw-gap+8,hw-gap+16,hw-tail+4,hw-fwd1,hw-fwd3
bench "$ROOT" "$OUT/placement" "$ROUNDS" "bolt,$(csv "${PLACED[@]}")"

# ---- the same benchmark with slot = i & (w - 1) ----------------------------
C=$ROOT/pool-counter
sed -i 's|rng_next(&s) % (uint64_t)w|(uint64_t)i \& (uint64_t)(w - 1)|' "$tmp/pool/main.c"
grep -q '(uint64_t)i & (uint64_t)(w - 1)' "$tmp/pool/main.c"
make -s -B -C "$tmp" pool/pool.exe CC="${CC:-clang}"
rm -rf "$C" && mkdir -p "$C"
# Same training input as prepare_micro.sh.
"$HERE/bolt_variants.sh" "$tmp/pool/pool.exe" "$C/pool" @BIN@ 20000000
bolt_layouts "$C/pool" "$tmp"
hand_written "$C/pool" --driver counter > /dev/null
bench "$C" "$OUT/counter" "$ROUNDS" \
  orig,bolt,bolt-copy,bolt-pi,pa-only-alloc,pa-only-free,pa-norb-pi,pa-cache-pi,pa-lto,hw-base,hw-base-head+1,hw-straight,hw-gap+1,hw-gap+2,hw-gap+4,hw-gap+8,hw-fwd1,hw-fwd3
