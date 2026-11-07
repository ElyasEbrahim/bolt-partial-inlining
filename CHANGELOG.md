# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- CI uses `actions/checkout@v7` (Node.js 24).

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

[Unreleased]: https://github.com/ElyasEbrahim/bolt-partial-inlining/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ElyasEbrahim/bolt-partial-inlining/releases/tag/v1.0.0
