#!/bin/bash
# Download (pinned, SHA-256 verified) and build the real-world workloads with
# relocations preserved (-Wl,--emit-relocs) so that BOLT can rewrite them.
#
#   SRC=/work/src OUT=/work/rw ./build.sh [sqlite] [lua] [cpython] [zstd]
set -euo pipefail
SRC=${SRC:-/work/src}
OUT=${OUT:-/work/rw}
JOBS=${JOBS:-$(nproc)}
CC=${CC:-clang}
LDRELOC="-fuse-ld=lld -Wl,--emit-relocs"
mkdir -p "$SRC" "$OUT"

fetch() { # url sha256
  local f; f="$SRC/$(basename "$1")"
  [ -f "$f" ] || curl -fsSL --retry 6 --retry-all-errors --retry-delay 5 -o "$f" "$1"
  echo "$2  $f" | sha256sum -c --quiet -
}

build_sqlite() {
  fetch https://www.sqlite.org/2026/sqlite-amalgamation-3540100.zip \
    0a9c8e34352dad46006aa82836d5383bff9dc6bc9ce5a60553c05aa30e6ad1f9
  fetch https://www.sqlite.org/2026/sqlite-src-3540100.zip \
    387e7f6cad4797b17848c07d453dc6606917bb356a6cfe5a3abafd38c240c71b
  local d=$OUT/sqlite/build; rm -rf "$d"; mkdir -p "$d"; cd "$d"
  python3 -I -c 'import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(".")
z = zipfile.ZipFile(sys.argv[2])
open("speedtest1.c", "wb").write(z.read("sqlite-src-3540100/test/speedtest1.c"))' \
    "$SRC/sqlite-amalgamation-3540100.zip" "$SRC/sqlite-src-3540100.zip"
  local A=sqlite-amalgamation-3540100
  $CC -O2 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -c $A/sqlite3.c -o sqlite3.o
  $CC -O2 -I$A -c speedtest1.c -o speedtest1.o
  $CC sqlite3.o speedtest1.o -o ../speedtest1 $LDRELOC -lm
}

build_lua() {
  fetch https://www.lua.org/ftp/lua-5.5.1.tar.gz \
    1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce
  local d=$OUT/lua/build; rm -rf "$d"; mkdir -p "$d"; cd "$d"
  tar xzf "$SRC/lua-5.5.1.tar.gz" --strip-components=1
  # Lua seeds its string hash from the clock and from addresses (ASLR) on
  # every start, which makes the executed path, and therefore BOLT profiles
  # and instruction counts, vary from run to run. A fixed seed makes every
  # run identical, as PYTHONHASHSEED=0 does for CPython.
  make -s -C src CC="$CC" MYCFLAGS="-O2 '-Dluai_makeseed()=0u'" MYLDFLAGS="$LDRELOC" \
    SYSCFLAGS="-DLUA_USE_LINUX" SYSLIBS="-Wl,-E -ldl" lua -j"$JOBS"
  cp src/lua ../lua
}

build_cpython() {
  fetch https://www.python.org/ftp/python/3.14.10/Python-3.14.10.tar.xz \
    de414a57119abef52784d8993e341d53aed635fc2b05c2607d9f98a2c5b72032
  local d=$OUT/cpython/build; rm -rf "$d"; mkdir -p "$d"; cd "$d"
  tar xJf "$SRC/Python-3.14.10.tar.xz" --strip-components=1
  # Default (non-LTO, non-PGO) release build, statically linked libpython,
  # installed into a private prefix that every variant uses as PYTHONHOME.
  ./configure -q CC="$CC" --prefix="$OUT/cpython/inst" --without-ensurepip \
    --disable-test-modules LDFLAGS="$LDRELOC" > configure.log
  make -s -j"$JOBS" > make.log 2>&1
  make -s altinstall > install.log 2>&1
  cp "$OUT/cpython/inst/bin/python3.14" ../python
}

build_zstd() {
  fetch https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz \
    eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
  local d=$OUT/zstd/build; rm -rf "$d"; mkdir -p "$d"; cd "$d"
  tar xzf "$SRC/zstd-1.5.7.tar.gz" --strip-components=1
  make -s -C programs zstd CC="$CC" LDFLAGS="$LDRELOC" HAVE_ZLIB=0 HAVE_LZMA=0 \
    HAVE_LZ4=0 HAVE_THREAD=0 -j"$JOBS"
  cp programs/zstd ../zstd
}

targets=("$@")
[ ${#targets[@]} -gt 0 ] || targets=(sqlite lua cpython zstd)
for t in "${targets[@]}"; do
  echo "== building $t"
  ( "build_$t" )
done
