# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/releases/tag/v1.0.0
