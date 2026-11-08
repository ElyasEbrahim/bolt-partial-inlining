# syntax=docker/dockerfile:1
#
# Reproducible evaluation image for profile-guided partial inlining in BOLT.
#
#   docker build -t bolt-partial-inline -f docker/Dockerfile .
#
# Stage "builder" checks out LLVM at the commit in patches/LLVM_COMMIT, builds
# an unmodified ("baseline") BOLT and a patched BOLT with the same toolchain,
# and runs the BOLT lit test suite for both. Stage "runtime" contains both
# BOLT builds and their test results, the evaluation workloads (built from
# pinned, SHA-256 verified sources) and the experiment scripts.

ARG LLVM_APT_VERSION=23

############################################################################
FROM ubuntu:24.04 AS base
ARG LLVM_APT_VERSION
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build python3 python3-psutil git ca-certificates \
      gnupg curl zlib1g-dev libzstd-dev xz-utils time \
      python3-numpy python3-scipy python3-matplotlib \
 && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-${LLVM_APT_VERSION} main" \
      > /etc/apt/sources.list.d/llvm.list \
 && apt-get update && apt-get install -y --no-install-recommends \
      clang-${LLVM_APT_VERSION} lld-${LLVM_APT_VERSION} llvm-${LLVM_APT_VERSION} \
 && for t in clang clang++ ld.lld lld llvm-ar llvm-nm llvm-objcopy llvm-objdump \
             llvm-readelf llvm-size llvm-strip; do \
      ln -sf /usr/bin/$t-${LLVM_APT_VERSION} /usr/local/bin/$t; done \
 && rm -rf /var/lib/apt/lists/*

############################################################################
FROM base AS builder
WORKDIR /llvm
COPY patches/ /llvm/patches/
# Shallow, sparse checkout of exactly the pinned commit.
RUN git init -q src && cd src \
 && git remote add origin https://github.com/llvm/llvm-project.git \
 && git sparse-checkout set bolt llvm cmake third-party libc \
 && git fetch -q --depth 1 --filter=blob:none origin "$(cat /llvm/patches/LLVM_COMMIT)" \
 && git checkout -q FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "$(cat /llvm/patches/LLVM_COMMIT)" \
 && git log -1 --format='%H %cd %s' > /llvm/COMMIT

# Configure, build and test BOLT. $1 = build directory.
RUN printf '%s\n' '#!/bin/bash' 'set -e' \
  'cmake -G Ninja -S /llvm/src/llvm -B "$1" -DCMAKE_BUILD_TYPE=Release \' \
  '  -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS=bolt \' \
  '  -DLLVM_TARGETS_TO_BUILD="AArch64;X86" -DCMAKE_C_COMPILER=clang \' \
  '  -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld \' \
  '  -DBOLT_CLANG_EXE=/usr/local/bin/clang -DBOLT_LLD_EXE=/usr/local/bin/ld.lld \' \
  '  -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_DOCS=OFF' \
  'ninja -C "$1" bolt bolt-test-depends' \
  'cd "$1" && (./bin/llvm-lit -q --output="$1/lit-results.json" tools/bolt/test > "$1/check-bolt.log" 2>&1 || true)' \
  > /usr/local/bin/build-bolt && chmod +x /usr/local/bin/build-bolt

# Baseline: unmodified upstream.
RUN build-bolt /llvm/build-baseline
# Patched: the patch applied on top of the same commit.
RUN cd /llvm/src && git apply --index /llvm/patches/0001-*.patch \
 && build-bolt /llvm/build-patched

# Install the user-facing tools and the test results of both builds.
RUN for v in baseline patched; do \
      mkdir -p /opt/bolt-$v/bin /opt/bolt-$v/lib; \
      cp /llvm/build-$v/bin/llvm-bolt /llvm/build-$v/bin/merge-fdata /opt/bolt-$v/bin/; \
      ln -s llvm-bolt /opt/bolt-$v/bin/perf2bolt; \
      cp /llvm/build-$v/lib/libbolt_rt_*.a /opt/bolt-$v/lib/; \
      cp /llvm/build-$v/check-bolt.log /llvm/build-$v/lit-results.json /opt/bolt-$v/; \
    done

############################################################################
FROM base AS runtime
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends valgrind pkg-config \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/bolt-baseline /opt/bolt-baseline
COPY --from=builder /opt/bolt-patched /opt/bolt-patched
COPY --from=builder /llvm/COMMIT /opt/LLVM_COMMIT
RUN ln -s /opt/bolt-patched /opt/bolt
ENV PATH=/opt/bolt/bin:$PATH BOLT_BIN=/opt/bolt/bin
# Real-world workloads first: they only depend on benchmarks/.
COPY benchmarks/ /workspace/benchmarks/
RUN mkdir -p /work && (SRC=/work/src OUT=/work/rw /workspace/benchmarks/realworld/build.sh \
      > /work/build-workloads.log 2>&1 || (tail -n 60 /work/build-workloads.log; exit 1)) \
 && find /work/rw -name '*.o' -delete
COPY LICENSE /workspace/LICENSE
COPY patches/ /workspace/patches/
COPY scripts/ /workspace/scripts/
WORKDIR /workspace
CMD ["/bin/bash"]
