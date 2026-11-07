#!/bin/bash
# Produce the BOLT variants of a workload binary.
#
#   bolt_variants.sh <orig-binary> <out-dir> <train-command...>
#
# The training command is run with the instrumented binary substituted for
# the token @BIN@. Variants written to <out-dir>:
#   orig        the compiler output (copied)
#   bolt        BOLT with the standard layout optimizations
#   bolt-copy   byte-identical copy of bolt (A/A control for the timing)
#   bolt-pi      bolt + -partial-inline (the optimization of this work)
#   bolt-pi-avg  ablation: average instead of worst-case profile model
#   bolt-pi-nofe ablation: frame elision disabled (frameless fast paths only)
#   bolt-inl     bolt + BOLT's existing whole-function inliner (-inline-all)
#   bolt-inl-pi  bolt-inl + -partial-inline
# Logs (including -dyno-stats) are written next to each variant.
set -euo pipefail
BOLT_BIN=${BOLT_BIN:-/opt/bolt/bin}
orig=$1; out=$2; shift 2
mkdir -p "$out"
cp "$orig" "$out/orig"

# 1. Instrument and collect a profile with the training input. The training
#    run has address space layout randomization disabled: Lua, SQLite and
#    CPython all take slightly different paths depending on where code, heap
#    and stack are mapped (e.g. hash tables keyed by addresses), so with ASLR
#    the profile, and therefore every BOLT variant, differs from run to run.
#    Timing runs (bench.py) keep ASLR enabled.
norand=()
if setarch -R true 2> /dev/null; then
  norand=(setarch -R)
else
  echo "warning: cannot disable ASLR (in Docker: --security-opt seccomp=unconfined)," \
       "the profile of $out may not be reproducible" >&2
fi
"$BOLT_BIN/llvm-bolt" "$out/orig" -instrument -o "$out/instr" \
  --instrumentation-file="$out/prof.fdata" --instrumentation-file-append-pid=0 \
  > "$out/instr.log" 2>&1
rm -f "$out/prof.fdata"
train=()
for a in "$@"; do train+=("${a//@BIN@/$out/instr}"); done
( "${norand[@]}" "${train[@]}" ) > "$out/train.stdout" 2> "$out/train.stderr"
test -s "$out/prof.fdata"

# 2. Optimize. The layout options follow the BOLT documentation.
LAYOUT=(-reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions
        -split-all-cold -split-eh -icf=1 -dyno-stats)
PI=(-partial-inline -v=1)
INL=(-inline-all -inline-ap)
opt() { local name=$1; shift
  /usr/bin/time -f "%e s %M KB" -o "$out/$name.time" \
    "$BOLT_BIN/llvm-bolt" "$out/orig" -o "$out/$name" -data "$out/prof.fdata" \
    "$@" > "$out/$name.log" 2>&1
}
opt bolt        "${LAYOUT[@]}"
cp "$out/bolt" "$out/bolt-copy"
opt bolt-pi     "${LAYOUT[@]}" "${PI[@]}"
opt bolt-pi-avg "${LAYOUT[@]}" "${PI[@]}" -partial-inline-profile-model=average
opt bolt-pi-nofe "${LAYOUT[@]}" "${PI[@]}" -partial-inline-frame-elision=false
opt bolt-inl    "${LAYOUT[@]}" "${INL[@]}"
opt bolt-inl-pi "${LAYOUT[@]}" "${INL[@]}" "${PI[@]}"
grep -h "BOLT-INFO: partial inlining: [0-9]" "$out/bolt-pi.log" || true
