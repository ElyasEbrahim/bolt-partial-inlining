#!/bin/bash
# Functional validation of --partial-inline on x86-64 binaries, using Docker's
# amd64 emulation on an AArch64 host. Performance is NOT measured (emulated).
#
#   x86_validate.sh <repo-dir> <dir-with-llvm-bolt> <llvm-project>/bolt/runtime
#
# <dir-with-llvm-bolt> contains the patched llvm-bolt for the host, e.g.
#   docker run --rm -v "$PWD/bin:/x" bolt-partial-inline cp /opt/bolt/bin/llvm-bolt /x
# and the runtime sources must be those of the commit in patches/LLVM_COMMIT.
#
# 1. amd64 container: compile the microbenchmarks, the end-to-end test program
#    and Lua 5.5.1 for x86-64 (-O2, --emit-relocs) and BOLT's instrumentation
#    runtime for x86-64.
# 2. host-arch container: instrument the x86-64 binaries with llvm-bolt.
# 3. amd64 container: collect profiles.
# 4. host-arch container: optimize with and without --partial-inline.
# 5. amd64 container: run all variants and compare their output with the
#    original binary.
set -euo pipefail
REPO=$(cd "$1" && pwd); BOLT=$(cd "$2" && pwd); RT=$(cd "$3" && pwd)
VOL=x86val
IMG_X86=${IMG_X86:-ubuntu:24.04}
IMG_DEV=${IMG_DEV:-bolt-dev}
docker volume create $VOL > /dev/null
x86() { docker run --rm --platform linux/amd64 -v $VOL:/v -v "$REPO":/repo:ro -v "$RT":/rt:ro "$IMG_X86" bash -c "$1"; }
dev() { docker run --rm -v $VOL:/v -v "$BOLT":/bolt:ro "$IMG_DEV" bash -c "$1"; }

echo "== 1. build x86-64 programs and runtime"
x86 '
set -e
apt-get update -qq >/dev/null && apt-get install -y -qq clang lld make curl ca-certificates >/dev/null
cd /v && rm -rf build && mkdir -p build bin && cd build
# BOLT instrumentation runtime (flags as in bolt/runtime/CMakeLists.txt).
echo "#define HAVE_ELF_H" > config.h
clang++ -O3 -std=c++17 -ffreestanding -fno-exceptions -fno-rtti -fno-stack-protector \
  -fPIC -fomit-frame-pointer -mno-sse -mgeneral-regs-only -I. -c /rt/instr.cpp -o instr.o
ar rc /v/bin/libbolt_rt_instr.a instr.o
# Microbenchmarks.
cp -r /repo/benchmarks/micro micro && make -s -C micro CC=clang all
for b in bufwrite memo trace pool mixed unsafe compute; do cp micro/$b/$b.exe /v/bin/$b; done
# End-to-end test program of the patch.
clang -O2 -fno-inline /repo/scripts/x86_e2e.c -o /v/bin/e2e -fuse-ld=lld -Wl,--emit-relocs
# Lua 5.5.1.
curl -fsSL --retry 6 --retry-all-errors --retry-delay 5 -o lua.tgz https://www.lua.org/ftp/lua-5.5.1.tar.gz
echo "1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce  lua.tgz" | sha256sum -c --quiet -
mkdir lua && tar xzf lua.tgz -C lua --strip-components=1
make -s -C lua/src CC=clang MYCFLAGS="-O2 '\''-Dluai_makeseed()=0u'\''" MYLDFLAGS="-fuse-ld=lld -Wl,--emit-relocs" \
  SYSCFLAGS=-DLUA_USE_LINUX SYSLIBS="-Wl,-E -ldl" lua -j8
cp lua/src/lua /v/bin/lua'

# name|training args|evaluation args
SPECS=(
  "bufwrite|3000000|6000000"
  "memo|2000000 20|4000000 20"
  "trace|3000000|6000000"
  "pool|2000000|4000000"
  "mixed|600000|1200000"
  "unsafe|2000000|4000000"
  "compute|2|3"
  "e2e|100000|300000"
  "lua|/repo/benchmarks/realworld/lua/bench.lua 1|/repo/benchmarks/realworld/lua/bench.lua 2"
)

echo "== 2. instrument"
dev "set -e; for b in bufwrite memo trace pool mixed unsafe compute e2e lua; do
  /bolt/llvm-bolt /v/bin/\$b -instrument -o /v/bin/\$b.instr \
    --runtime-instrumentation-lib=/v/bin/libbolt_rt_instr.a \
    --instrumentation-file=/v/bin/\$b.fdata --instrumentation-file-append-pid=0 > /dev/null; done"

echo "== 3. train"
for s in "${SPECS[@]}"; do IFS='|' read -r n t e <<< "$s"
  x86 "set -e; rm -f /v/bin/$n.fdata; /v/bin/$n.instr $t > /dev/null; test -s /v/bin/$n.fdata"; done

echo "== 4. optimize"
dev "set -e; L='-reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions -split-all-cold -split-eh -icf=1'
for b in bufwrite memo trace pool mixed unsafe compute e2e lua; do
  /bolt/llvm-bolt /v/bin/\$b -o /v/bin/\$b.bolt -data /v/bin/\$b.fdata \$L > /v/bin/\$b.bolt.log 2>&1
  /bolt/llvm-bolt /v/bin/\$b -o /v/bin/\$b.pi -data /v/bin/\$b.fdata \$L -partial-inline -v=1 > /v/bin/\$b.pi.log 2>&1
  printf '%-9s ' \$b; grep -h 'partial inlining: [0-9]' /v/bin/\$b.pi.log | sed 's/BOLT-INFO: partial inlining: //'
done"

echo "== 5. run and compare"
fail=0
for s in "${SPECS[@]}"; do IFS='|' read -r n t e <<< "$s"
  if x86 "set -e; cd /v/bin; for v in $n $n.bolt $n.pi; do ./\$v $e > /tmp/\$v.out; done
          cmp /tmp/$n.out /tmp/$n.bolt.out && cmp /tmp/$n.out /tmp/$n.pi.out"; then
    echo "OK        $n: original, bolt and bolt + --partial-inline produce identical output"
  else
    echo "MISMATCH  $n"; fail=1
  fi
done
exit $fail
