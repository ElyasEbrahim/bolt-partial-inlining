# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **clang workload** (`benchmarks/realworld/clang`), built with the in-tree
  Clang-BOLT rules:
  - clang at the pinned LLVM commit, built with the settings of
    `clang/cmake/caches/BOLT.cmake` (ClangIR off);
  - the training of `clang/utils/perf-training` (hello world, then
    configure LLVM and build LLVMSupport);
  - the BOLT options of `perf-helper.py bolt-optimize`;
  - timed on compiling the SQLite amalgamation (`-O2`) and LLVM's
    `Verifier.cpp` and `GVN.cpp` (`-O3`), with the object files checked in
    every run;
  - also included in the instruction counts and the coverage analysis.
- **Branch relaxation variants** for the real programs: `bolt-nocl` and
  `bolt-pi-nocl` use the AArch64 branch relaxation that upstream BOLT used
  before 2026-11-23 (`-relax-with-clusters=false`). Upstream's new default,
  clustered relaxation, changes the baseline substantially for jq. The report
  has a new section "Branch relaxation".
- `scripts/bolt_variants.sh`: optional settings `INSTR`, `APPEND_PID`,
  `BOLT_LAYOUT` and `RELAX_LEGACY`.

### Changed

- The patch is rebased onto llvm-project `1be60cbf47e9` (2026-11-25), the
  base of the upstream proposal. The cherry-pick had no conflicts and the code
  is unchanged. One line of the runtime test is reformatted (clang-format).
  The commit message no longer quotes results.
- The image installs CMake 3.31.10, which LLVM requires since 2026-11-19.
- `make check-patch` and `make x86-validate` check out the pinned commit
  again when `patches/LLVM_COMMIT` changes.
- All results come from a new complete run (2026-11-27, image
  `0fd6b39579d8`, 2 h 33 min). Main changes:
  - **clang:** 1.015x [1.013, 1.017] over Clang-BOLT; 2,115 call sites; 22%
    of the profiled direct calls and 2.1% of the executed instructions
    avoided; +0.39% hot code.
  - **jq:** 1.124x. With the previous branch relaxation the pass gives
    1.068x, as in 1.3.1 (1.069x); the difference compensates for overhead
    that the new relaxation adds to jq's baseline.
  - **Lua:** 1.008x, which disappears with the previous relaxation.
  - **zstd** with the complete profile: one compression call site, +0.59%
    executed instructions, no measurable change in run time.
  - **Microbenchmarks** as before within 1.1%, except `memo` 1.067x and
    `bufwrite` 1.024x. With the same binaries, the first, unpublished run of
    this version measured 1.020x and 1.003x: loops bound by store-to-load
    chains vary between runs.
- Design document and README rewritten for these results.
  - New in the design document: the clang workload (Section 5.2), branch
    relaxation, between-run variation (Section 5.3), and the zstd profile and
    upstream's baseline change (Section 5.7).
  - Two new limitations in Section 7: no cost model for re-execution, and the
    dependence on the branch relaxation.

### Fixed

- **zstd's training profile now contains compression.** The training runs
  two processes (compress, then decompress), and both wrote the same profile
  file. BOLT's runtime truncates that file, so the decompression run
  overwrote the compression profile. In versions 1.0.0-1.3.1, BOLT therefore
  optimized only zstd's decompression code, and the zstd-compress results of
  those versions do not test BOLT or the pass on compression. Each training
  process now writes its own profile, and the profiles are merged.

## [1.3.1] - 2026-11-26

### Added

- `CODE_OF_CONDUCT.md` (the LLVM Community Code of Conduct), issue templates
  for miscompilations and performance results, and a pull-request template.
- Design document, Section 5.7: a second complete run of version 1.3.0 from a
  fresh clone with the release image reproduced all profiles and BOLT outputs
  byte for byte and every headline result within 1%; the nominal libxml2
  gain did not reproduce (1.002x), and jq on top of `-inline-all` measured
  1.006x.

- README: how to compare a rebuilt image with the release image; a rebuild
  from the same sources can show another image ID, because Docker writes a
  new image index for every build.

### Fixed

- Design document: `mixed`, `trace` and `memo` execute 13-16% fewer
  instructions (not 13-25%); clang left 3 of the 8 fast-path functions of the
  microbenchmarks without shrink-wrapping (not 3 of 6); the confidence
  interval of `bufwrite` excludes 1.0 as well as that of libxml2; `too-large`
  rejects 0-7 callees per program (not 1-7); the `bolt-pi-skip` analysis is
  in Section 5.3; Section 5 marks the numbers that do not come from the
  published run.
- Design document, Sections 5.6, 5.7 and 7: BOLT does not rewrite Lua's
  interpreter loop with `switch` dispatch either (an exploratory build, which
  is also 12.8% slower), and Lua's training profile depends on the path and
  the environment of the training run, both of which `make experiments`
  fixes.
- CONTRIBUTING: export the patch to its existing file name; `git format-patch
  -o` shortens it, and `make check-patch` would then find two patch files.

## [1.3.0] - 2026-11-17

### Added

- Fast paths through the first iteration of a loop: the back edges of a loop
  in the fast region leave the region like any other slow exit, so a lookup
  that usually succeeds at the first node of a hash chain is copied up to the
  point where it would move on. The worst-case profile model now also bounds
  the slow-path calls by the profile counts of the slow-exit edges, because
  the counts of a loop header mix the first iteration with later ones.
  Hidden option `--partial-inline-loops` (on).
- Saved registers: a register that the fast path overwrites before its
  decision although the callee reads its entry value again when it
  re-executes (`p = p->next`) is copied to a scratch register at the start of
  the copy and restored in front of the fallback call. AArch64 general
  purpose registers; new MCPlusBuilder hook `createRegisterCopy()`. Hidden
  option `--partial-inline-save-regs` (on).
- Lit tests `AArch64/partial-inline-loop.s` and
  `AArch64/partial-inline-save-regs.s`; the end-to-end runtime test covers
  both cases.
- Microbenchmarks `lookup` (hash chain lookup, mostly hits the first node),
  `lookup-deep` (the same binary with most lookups beyond the first node) and
  `chain` (argument overwritten before the decision).
- Variant `bolt-pi-noext`: the pass without both extensions, which writes the
  same binaries as version 1.2.0; a report table compares it with `bolt-pi`.
- `scripts/coverage.py` and report tables: which calls of the real programs
  the pass reaches, the rejected callees by reason, and the effect of the
  region size limits (design document, Section 5.6).

### Changed

- `unsafe` contains only the case of a store before the decision. Its second
  function, which overwrites its argument before the decision, is the new
  `chain` microbenchmark, since the pass now transforms it.
- `AArch64/partial-inline-reject.s` checks a clobbered floating-point
  argument instead of a general purpose one, and a loop at the entry that
  usually iterates is now rejected as a cold fast path.
- The Dockerfile builds the baseline BOLT and the real-world workloads before
  it copies the patch and the scripts, so changing either does not rebuild
  them.
- All results are from a new continuous run of `make experiments`. In it,
  libxml2's confidence interval excludes 1.0 for the first time (1.014x
  [1.005, 1.031]); the same binaries measured 1.000x and 1.009x in the two
  previous runs, and the design document does not count it as a gain.

### Fixed

- Version 1.2.0 presented partial inlining on top of `-inline-all` on jq as a
  resolved 2.4% gain (1.024x [1.015, 1.028]) and the non-significant result
  of 1.1.0 as superseded. The new run measured 1.011x [1.000, 1.022], p = 0.10,
  for the same binaries: the effect is about 1-2% and significant in one of
  three runs.
- The real-world workloads build reproducibly. CPython embeds its build time,
  and an image built from the Dockerfile of an earlier version at a later
  time contains a different CPython binary (about 45,000 bytes differ,
  including code). `benchmarks/realworld/build.sh` sets `SOURCE_DATE_EPOCH`;
  a second build in a fresh container now gives byte-identical binaries for
  all six programs.

## [1.2.0] - 2026-11-13

### Added

- Analysis of the `pool` slowdown on hand-written variants of its loop
  (`scripts/pool_loop.py`, extended `scripts/pool_analysis.sh`): instructions
  added or removed between the two inlined fast paths, 16 code placements,
  register copies instead of reloads, and a build of the benchmark without
  the random number generator in its loop. The hand-written loops that mirror
  BOLT outputs are timed next to them.

### Changed

- The base image of the evaluation image is pinned by digest. The tag
  `ubuntu:24.04` had moved since 1.1.0, so that `make image` rebuilt every
  layer, including the toolchain. With the pin, the BOLT builds, the compiler
  and the workload binaries are byte-identical to those of 1.1.0.
- `results/pool-analysis/` has one directory per experiment.
- All results are from a new continuous run of `make experiments`.

### Fixed

- Explanation of the `pool` slowdown (design document, Sections 1, 5.5, 6 and
  7). Versions 1.0.0 and 1.1.0 attributed it to BOLT's ext-tsp block order
  and stated that with another block order the partially inlined code is as
  fast as the compiler's LTO inlining. Both statements are withdrawn. Nops
  between the two inlined regions have the same effect as another block
  order, and the equal speed was the lower bound set by the benchmark's
  random number generator: without it, partial inlining is 20% slower than
  the baseline and LTO 3.1 times faster. The run time of this loop depends
  non-monotonically on the number of instructions between a store and the
  load that reads it back, with or without the transformation, and no
  mitigation in the pass was found.
- jq on top of `-inline-all`: 1.024x [1.015, 1.028] in the new run. Version
  1.1.0 reported 1.015x [0.978, 1.040] for byte-identical binaries and called
  the difference not significant.

## [1.1.0] - 2026-11-08

### Added

- Real-world workloads jq 1.8.2 and libxml2 2.15.4 (`xmllint`), selected by a
  screening of six candidate programs whose procedure and results are in the
  design document; their hash seeds are made constant for reproducible
  profiles.
- Variant `bolt-pi-skip` (jq: partial inlining without the trivial callee
  `jv_get_kind`) and a report table that separates the share of the speedup
  that only partial inlining achieves from the share BOLT's existing
  `-inline-all` achieves as well.

### Changed

- CI uses `actions/checkout@v7` (Node.js 24).
- The evaluation image installs `pkg-config` (needed by libxml2's build).

## [1.0.0] - 2026-11-07

First public release. It replaces an earlier, unversioned snapshot of this
repository whose results had been collected in several separate runs.

### Added

- BOLT pass `partial-inlining` (`--partial-inline`) against llvm-project
  `0a0e65b2e8ff`: profile-guided partial inlining of callee fast paths with
  stack frame elision, callee-saved register renaming and a re-execution
  fallback; worst-case and average profile models; options
  `--partial-inline-{max-insns,max-blocks,min-fast-ratio,profile-model,
  min-count,coverage,frame-elision}` and `--print-partial-inline`.
- MCPlusBuilder hooks `analyzeFrameInstruction`, `getCallSiteScratchRegs` and
  `getFullyDefinedReg` with AArch64 and x86-64 implementations.
- Seven lit tests, including an end-to-end runtime test with pointer
  authentication; BOLT documentation for the new options.
- Evaluation: microbenchmarks, build scripts for SQLite, Lua, CPython and
  zstd, benchmarking and reporting scripts, Docker image, design document and
  results of one continuous evaluation run.

### Changed (compared with the unversioned snapshot)

- All results come from one invocation of `scripts/run_experiments.sh`
  (`make experiments`), which records the environment and a timeline.
- Reproducible profiles: training runs disable ASLR (`setarch -R`) and Lua is
  built with a fixed hash seed. Previously the Lua, SQLite and CPython
  profiles, and therefore their BOLT variants, differed between runs.
- Timing and instruction counts run every variant from a fresh copy at the
  same path. The file name of a variant shifted the initial stack and, for
  example, changed Lua's executed instruction count by up to 0.6%. A
  byte-identical copy of the baseline (`bolt-copy`) is measured as an A/A
  control.
- Corrected result: the snapshot reported a 2.5% speedup on Lua. It was a
  per-binary measurement bias (each variant ran under its own file name from
  its own file pages); with every run executing a fresh copy at the same path,
  none of the real programs shows a measurable run-time change (all within
  +-1%).
- The BOLT test-suite comparison (`make check-bolt`) is extracted from the
  final image and fails if the result of any existing test changes.

[Unreleased]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.3.1...HEAD
[1.3.1]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/releases/tag/v1.0.0
