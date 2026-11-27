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
#   bolt-pi-noext ablation: without fast paths through the first iteration of
#                a loop and without saving overwritten registers (the pass as
#                in version 1.2.0). Only kept if it differs from bolt-pi;
#                otherwise bolt-pi-noext.identical is written instead.
#   bolt-inl     bolt + BOLT's existing whole-function inliner (-inline-all)
#   bolt-inl-pi  bolt-inl + -partial-inline
#   bolt-pi-skip only if PI_SKIP is set: bolt-pi with
#                -partial-inline-skip=$PI_SKIP (analysis of single callees)
#   bolt-nocl, bolt-pi-nocl  only if RELAX_LEGACY=1: bolt and bolt-pi with
#                the AArch64 branch relaxation that upstream BOLT used before
#                2026-11-23, stub insertion (-relax-with-clusters=false),
#                instead of the clustered relaxation that is now the default
# Logs (including -dyno-stats) are written next to each variant.
#
# Optional settings (environment):
#   INSTR        path of the instrumented binary (default: <out-dir>/instr).
#                clang is instrumented next to itself, where it finds its
#                resource headers, as in the in-tree Clang-BOLT rules.
#   APPEND_PID=1 the training runs many processes: each writes its own
#                profile (--instrumentation-file-append-pid), and the profiles
#                are merged with merge-fdata.
#   BOLT_LAYOUT  layout options instead of the default ones below.
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
instr=${INSTR:-$out/instr}
pid=(--instrumentation-file-append-pid=0)
[ "${APPEND_PID:-0}" = 1 ] && pid=(--instrumentation-file-append-pid)
"$BOLT_BIN/llvm-bolt" "$out/orig" -instrument -o "$instr" \
  --instrumentation-file="$out/prof.fdata" "${pid[@]}" > "$out/instr.log" 2>&1
rm -f "$out/prof.fdata" "$out"/prof.fdata.*.fdata
train=()
for a in "$@"; do train+=("${a//@BIN@/$instr}"); done
( "${norand[@]}" "${train[@]}" ) > "$out/train.stdout" 2> "$out/train.stderr"
if [ "${APPEND_PID:-0}" = 1 ]; then
  "$BOLT_BIN/merge-fdata" "$out"/prof.fdata.*.fdata > "$out/prof.fdata" 2> "$out/merge.log"
  rm -f "$out"/prof.fdata.*.fdata
fi
test -s "$out/prof.fdata"

# 2. Optimize. The layout options follow the BOLT documentation.
LAYOUT=(-reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions
        -split-all-cold -split-eh -icf=1 -dyno-stats)
[ -n "${BOLT_LAYOUT:-}" ] && read -r -a LAYOUT <<< "$BOLT_LAYOUT"
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
opt bolt-pi-noext "${LAYOUT[@]}" "${PI[@]}" -partial-inline-loops=false \
  -partial-inline-save-regs=false
# The note section records the command line, which differs by construction.
OBJCOPY=${OBJCOPY:-llvm-objcopy}
"$OBJCOPY" --remove-section=.note.bolt_info "$out/bolt-pi" "$out/.pi.tmp"
"$OBJCOPY" --remove-section=.note.bolt_info "$out/bolt-pi-noext" "$out/.noext.tmp"
if cmp -s "$out/.pi.tmp" "$out/.noext.tmp"; then
  rm -f "$out/bolt-pi-noext"
  echo "byte-identical to bolt-pi" > "$out/bolt-pi-noext.identical"
fi
rm -f "$out/.pi.tmp" "$out/.noext.tmp"
opt bolt-inl    "${LAYOUT[@]}" "${INL[@]}"
opt bolt-inl-pi "${LAYOUT[@]}" "${INL[@]}" "${PI[@]}"
if [ -n "${PI_SKIP:-}" ]; then
  opt bolt-pi-skip "${LAYOUT[@]}" "${PI[@]}" -partial-inline-skip="$PI_SKIP"
  echo "$PI_SKIP" > "$out/bolt-pi-skip.skipped"
fi
if [ "${RELAX_LEGACY:-0}" = 1 ]; then
  opt bolt-nocl    "${LAYOUT[@]}" -relax-with-clusters=false
  opt bolt-pi-nocl "${LAYOUT[@]}" "${PI[@]}" -relax-with-clusters=false
fi
grep -h "BOLT-INFO: partial inlining: [0-9]" "$out/bolt-pi.log" || true
