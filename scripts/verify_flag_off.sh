#!/bin/bash
# The patch must not change BOLT's output unless --partial-inline is given:
# optimize every workload with the unmodified mainline llvm-bolt and with the
# patched llvm-bolt (same options, no --partial-inline) and compare the output
# binaries byte by byte. The .note.bolt_info section is removed first: it
# records the BOLT revision and the command line (paths of llvm-bolt and of
# the output file), which differ by construction.
set -uo pipefail
OBJCOPY=${OBJCOPY:-llvm-objcopy}
BASE=${BASE_BIN:-/opt/bolt-baseline/bin}
PATCHED=${PATCHED_BIN:-/opt/bolt-patched/bin}
ROOT=${ROOT:-/work/out}
LAYOUT=(-reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions
        -split-all-cold -split-eh -icf=1 -dyno-stats)
fail=0
for d in "$ROOT"/*/; do
  [ -f "$d/orig" ] && [ -f "$d/prof.fdata" ] || continue
  w=$(basename "$d")
  for opts in "" "-inline-all -inline-ap"; do
    "$BASE/llvm-bolt" "$d/orig" -o /tmp/base.bin -data "$d/prof.fdata" \
      "${LAYOUT[@]}" $opts > /dev/null 2>&1
    "$PATCHED/llvm-bolt" "$d/orig" -o /tmp/patched.bin -data "$d/prof.fdata" \
      "${LAYOUT[@]}" $opts > /dev/null 2>&1
    "$OBJCOPY" --remove-section=.note.bolt_info /tmp/base.bin
    "$OBJCOPY" --remove-section=.note.bolt_info /tmp/patched.bin
    if cmp -s /tmp/base.bin /tmp/patched.bin; then
      echo "IDENTICAL  $w ${opts:-(layout only)}  sha256=$(sha256sum < /tmp/base.bin | cut -c1-16)"
    else
      echo "DIFFERENT  $w ${opts:-(layout only)}"; fail=1
    fi
  done
done
exit $fail
