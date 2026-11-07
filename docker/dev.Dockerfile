# Development / build environment for LLVM BOLT on Linux AArch64 (and x86-64).
# Provides a recent clang/lld (from apt.llvm.org) for building BOLT, running
# its lit test-suite and compiling the evaluation workloads.
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ARG LLVM_APT_VERSION=23
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build python3 python3-pip python3-venv git ca-certificates \
      gnupg curl zlib1g-dev libzstd-dev \
      valgrind time hyperfine file bc gdb less vim-tiny xz-utils \
      python3-numpy python3-scipy python3-matplotlib python3-psutil \
 && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-${LLVM_APT_VERSION} main" > /etc/apt/sources.list.d/llvm.list \
 && apt-get update && apt-get install -y --no-install-recommends \
      clang-${LLVM_APT_VERSION} lld-${LLVM_APT_VERSION} llvm-${LLVM_APT_VERSION} clang-format-${LLVM_APT_VERSION} \
 && for t in clang clang++ clang-format git-clang-format ld.lld lld llvm-ar llvm-nm llvm-objcopy llvm-objdump llvm-readelf llvm-size llvm-strip; do \
      ln -sf /usr/bin/$t-${LLVM_APT_VERSION} /usr/local/bin/$t; done \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
