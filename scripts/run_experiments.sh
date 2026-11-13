#!/bin/bash
# Run the complete evaluation in one continuous session (inside the Docker
# image, see docker/Dockerfile). Every result in results/ is produced by one
# invocation of this script:
#
#   1. record the environment (CPU, kernel, toolchain, BOLT revisions),
#   2. build the BOLT variants of the micro and real-world workloads from
#      instrumentation profiles collected on training inputs,
#   3. check that the patched llvm-bolt without --partial-inline writes
#      byte-identical binaries to the unmodified mainline llvm-bolt (abort if
#      not),
#   4. time all variants (interleaved rounds, every output verified):
#      microbenchmarks with MICRO_ROUNDS rounds, real programs with RW_ROUNDS,
#   5. analyze the slowdown of the 'pool' microbenchmark (pool_analysis.sh),
#   6. count executed instructions with valgrind,
#   7. write the report (REPORT.md, report.json, plots).
#
#   OUT=/work/results ./run_experiments.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
export BOLT_BIN=${BOLT_BIN:-/opt/bolt/bin}
export ROOT=${ROOT:-/work/out}
OUT=${OUT:-/work/results}
MICRO_ROUNDS=${MICRO_ROUNDS:-15}
RW_ROUNDS=${RW_ROUNDS:-30}
MICRO=(bufwrite memo trace pool mixed memo-lowhit unsafe compute)
REAL=(sqlite lua cpython zstd-compress zstd-decompress jq libxml2)

# Training runs need ASLR disabled for reproducible profiles (bolt_variants.sh).
if ! setarch -R true 2> /dev/null; then
  echo "error: cannot disable ASLR with setarch -R; run the container with" \
       "--security-opt seccomp=unconfined (see Makefile, target experiments)" >&2
  exit 1
fi

# Timing runs execute every binary from a fresh copy in $STAGE (bench.py
# --stage-dir), preferably a tmpfs (the Makefile mounts one at /stage).
STAGE=${STAGE:-/stage}
if [ ! -d "$STAGE" ] || [ ! -w "$STAGE" ]; then
  STAGE=$(mktemp -d)
  echo "warning: $STAGE is used for staging binaries (no tmpfs at /stage)" >&2
fi

# Start from empty directories ($OUT may be a mount point, keep the directory).
mkdir -p "$OUT" "$ROOT"
find "$OUT" "$ROOT" -mindepth 1 -delete
mkdir -p "$OUT/micro" "$OUT/realworld" "$OUT/pool-analysis"
stamp() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a "$OUT/timeline.log"; }

stamp "start"
{
  echo "date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host:        $(uname -srm)"
  echo "cpu:         $(grep -m1 -E 'CPU implementer' /proc/cpuinfo | cut -d: -f2) implementer," \
       "$(nproc) online CPUs"
  echo "features:    $(grep -m1 Features /proc/cpuinfo | cut -d: -f2)"
  echo "memory:      $(grep MemTotal /proc/meminfo | awk '{print $2 " kB"}')"
  echo "image:       ${IMAGE_ID:-unknown}"
  echo "llvm commit: $(cat /opt/LLVM_COMMIT 2>/dev/null || echo unknown)"
  echo "clang:       $(clang --version | head -1)"
  echo "lld:         $(ld.lld --version)"
  echo "python:      $(python3 --version)"
  echo "valgrind:    $(valgrind --version)"
  echo "llvm-bolt (patched):  $("$BOLT_BIN/llvm-bolt" --version | grep -i 'BOLT revision' | xargs)"
  echo "llvm-bolt (baseline): $(/opt/bolt-baseline/bin/llvm-bolt --version | grep -i 'BOLT revision' | xargs)"
  echo "rounds:      micro=$MICRO_ROUNDS real-world=$RW_ROUNDS"
  echo "staging:     $STAGE ($(stat -f -c %T "$STAGE"))"
  echo "aslr:        disabled for training runs (setarch -R), enabled for timing runs" \
       "(randomize_va_space=$(cat /proc/sys/kernel/randomize_va_space))"
} > "$OUT/environment.txt"

stamp "build BOLT variants (microbenchmarks)"
"$HERE/prepare_micro.sh" > "$OUT/prepare-micro.log" 2>&1
stamp "build BOLT variants (real-world programs)"
"$HERE/prepare_realworld.sh" > "$OUT/prepare-realworld.log" 2>&1

stamp "flag-off identity check"
"$HERE/verify_flag_off.sh" > "$OUT/flag-off-identity.txt" 2>&1

stamp "timing: microbenchmarks"
python3 "$HERE/bench.py" --root "$ROOT" --out "$OUT/micro" \
  --rounds "$MICRO_ROUNDS" --only "${MICRO[@]}" --stage-dir "$STAGE" \
  > "$OUT/micro/bench.log" 2>&1
stamp "timing: real-world programs"
python3 "$HERE/bench.py" --root "$ROOT" --out "$OUT/realworld" \
  --rounds "$RW_ROUNDS" --only "${REAL[@]}" --stage-dir "$STAGE" \
  > "$OUT/realworld/bench.log" 2>&1

stamp "pool analysis"
STAGE=$STAGE OUT="$OUT/pool-analysis" "$HERE/pool_analysis.sh" > "$OUT/pool-analysis/bench.log" 2>&1

stamp "instruction counts"
python3 "$HERE/icount.py" --root "$ROOT" --out "$OUT" --stage-dir "$STAGE" \
  > "$OUT/icount.log" 2>&1

stamp "report"
mkdir -p "$OUT/bolt-logs"
for d in "$ROOT"/*/; do
  w=$(basename "$d")
  mkdir -p "$OUT/bolt-logs/$w"
  cp "$d"/*.log "$d"/*.time "$OUT/bolt-logs/$w/" 2>/dev/null || true
done
mkdir -p "$OUT/bolt-logs/pool-counter"
cp "$ROOT"/pool-counter/pool/*.log "$OUT/bolt-logs/pool-counter/" 2>/dev/null || true
python3 "$HERE/report.py" --root "$ROOT" --results "$OUT" \
  --summary "$OUT/micro/summary.json" "$OUT/realworld/summary.json" \
  --icount "$OUT/icount.json" --pool "$OUT/pool-analysis" \
  > "$OUT/report.log" 2>&1
stamp "done"
