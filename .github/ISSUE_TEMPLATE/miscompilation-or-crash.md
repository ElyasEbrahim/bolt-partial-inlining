---
name: Miscompilation or crash
about: A binary optimized with --partial-inline behaves differently, or llvm-bolt fails
labels: bug
---

**What happens**
<!-- Wrong output, crash of the optimized program, or an llvm-bolt error. -->

**llvm-bolt command line and output**
<!-- The full command line and the `BOLT-INFO: partial inlining` lines
     (run with -v=1, or -v=2 to see why callees were rejected). -->

**Reproducer**
<!-- The smallest input binary and profile that reproduce the problem, and
     the output of `--print-partial-inline --print-only=<caller>`.
     `--partial-inline-max-sites=N` and `--partial-inline-skip=<functions>`
     help to find the call site. -->

**Environment**
<!-- Target (AArch64 or x86-64), OS, compiler of the input binary, and the
     LLVM commit or release of this repository. -->
