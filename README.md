# Partial Inlining for LLVM BOLT

[![CI](https://github.com/ElyasEbrahim/bolt-partial-inlining/actions/workflows/ci.yml/badge.svg)](https://github.com/ElyasEbrahim/bolt-partial-inlining/actions/workflows/ci.yml)
[![License: Apache-2.0 WITH LLVM-exception](https://img.shields.io/badge/license-Apache--2.0%20WITH%20LLVM--exception-blue.svg)](LICENSE)

Profile-guided **partial inlining with stack frame elision** for the
[LLVM BOLT](https://github.com/llvm/llvm-project/tree/main/bolt) post-link
optimizer, enabled with `llvm-bolt --partial-inline`.

Many hot functions return early after a few instructions (a cache hit, a
buffer with room, a disabled log level, a non-empty free list) but are too
large to inline, live in another translation unit, or were not shrink-wrapped
by the compiler, so every call also pays for the prologue and epilogue. For
each hot direct call site, the new BOLT pass copies the callee's profile-hot
fast path into the caller,

* drops the callee's frame setup and teardown on that path (stack pointer
  updates, callee-saved spills and reloads, frame pointer setup, return
  address signing, CFI, BTI landing pads),
* renames callee-saved registers used as temporaries to scratch registers that
  are provably dead at the call site, and
* falls back to the original call on every other path. The copied region is
  side-effect free and re-executable up to the fast/slow decision, so the
  callee itself is left unchanged.

The patch applies to llvm-project
[`0a0e65b2e8ff`](https://github.com/llvm/llvm-project/commit/0a0e65b2e8ff6043d85ab07c4d23ea18bf0b9b7d)
(2026-11-06). AArch64 is fully supported; on x86-64 only fast paths that do
not touch the stack are inlined.

## Results

Apple M3 Max, Linux/AArch64 VM, clang 23 `-O2`/`-O3` without LTO, speedup of
`--partial-inline` over the BOLT baseline (`-reorder-blocks=ext-tsp
-reorder-functions=cdsort -split-functions ...`), median of paired rounds with
95% confidence interval. All numbers come from one run of `make experiments`;
see [`results/REPORT.md`](results/REPORT.md) and
[Section 5 of the design document](docs/design.md#5-experimental-evaluation).

| Workload | Pattern | Speedup | Executed instructions |
|---|---|---|---:|
| `mixed` | always-fast and always-slow call sites of one callee | **2.728x** [2.707, 2.748] | -13.0% |
| `trace` | disabled tracing hook | **1.663x** [1.657, 1.679] | -16.0% |
| `memo` | memoization cache hit, callee not shrink-wrapped | **1.018x** [1.014, 1.020] | -16.3% |
| `bufwrite` | buffered writer, bound by a store-to-load chain | 1.003x [1.000, 1.007] | -23.9% |
| `pool` | free-list allocator, bound by store-to-load chains between the two inlined fast paths | 0.953x [0.949, 0.957] | -25.0% |
| `unsafe`, `memo-lowhit`, `compute` | unsafe, too cold, or no calls | 0.999-1.003x | 0.00% |
| jq 1.8 | JSON processor, 26% of direct calls avoided | **1.070x** [1.060, 1.072] | -2.0% |
| jq 1.8, without the trivial callee `jv_get_kind` | share no existing BOLT pass achieves | **1.023x** [1.005, 1.033] | -0.9% |
| SQLite 3.54, Lua 5.5, CPython 3.14, zstd 1.5, libxml2 2.15 | real programs | 0.992-1.009x, all CIs include 1.0 | -1.5% to 0.0% |
| A/A control | byte-identical copy of the baseline | 0.990-1.010x | - |

The pass removes the call, return and frame overhead of hot fast paths and is
effective where such calls dominate the run time. Among six real programs it
speeds up jq by 7.0%. Most of that comes from a one-instruction callee that
BOLT's existing `-inline-all` inlines as well (1.094x on its own, 1.122x
together with `--partial-inline`). On the other real programs the saved
instructions (at most 1.5%) are below the resolution of the measurement
(about +-1%, see the A/A control). jq and libxml2 were chosen by a screening of
six candidate programs whose procedure and results are in the design
document. Without `--partial-inline`, the patched `llvm-bolt` writes
byte-identical binaries to upstream, and no existing BOLT test changes its
result.

The pass can also lose: `pool` is 5% slower although it executes 25% fewer
instructions. Its two inlined fast paths store and reload the same fields in
every loop iteration, and on this core the run time of such a loop depends on
the exact number of instructions between a store and its reload (0.82x to
1.09x when single instructions are added or removed). The pass has no cost
model for this; see
[Section 5.5 of the design document](docs/design.md#55-analysis).

## Repository layout

| Path | Content |
|---|---|
| [`patches/`](patches/) | the LLVM patch (pass, target hooks, 7 lit tests, documentation) and the LLVM commit it applies to |
| [`docs/design.md`](docs/design.md) | design document: problem, design, correctness argument, implementation, evaluation, limitations |
| [`benchmarks/`](benchmarks/) | microbenchmarks and build scripts for SQLite, Lua, CPython, zstd, jq and libxml2 |
| [`scripts/`](scripts/) | profiling, BOLT variant generation, benchmarking, checks and reporting |
| [`results/`](results/) | the measurements of one complete evaluation run, see [`results/README.md`](results/README.md) |
| [`docker/`](docker/) | reproducible evaluation image and development environment |

## Getting started

### Build BOLT with the patch

```bash
git clone https://github.com/llvm/llvm-project.git && cd llvm-project
git checkout 0a0e65b2e8ff6043d85ab07c4d23ea18bf0b9b7d
git am /path/to/bolt-partial-inlining/patches/0001-*.patch
cmake -G Ninja -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=bolt -DLLVM_TARGETS_TO_BUILD="AArch64;X86"
ninja -C build bolt        # llvm-bolt, perf2bolt, merge-fdata, instrumentation runtime
```

### Use it

Link the program with `-Wl,--emit-relocs`, collect a profile (instrumentation
or `perf`) and add `--partial-inline` to the usual BOLT options:

```bash
llvm-bolt prog -instrument -o prog.instr && ./prog.instr <training input>
llvm-bolt prog -o prog.bolt -data /tmp/prof.fdata \
  -reorder-blocks=ext-tsp -reorder-functions=cdsort -split-functions \
  --partial-inline -v=1
```

| Option | Default | Meaning |
|---|---|---|
| `--partial-inline` | off | enable the pass |
| `--partial-inline-min-fast-ratio` | 60 | minimum estimated fast-path percentage at a call site |
| `--partial-inline-profile-model` | `worst-case` | `worst-case` or `average` estimate of a call site's fast-path share |
| `--partial-inline-max-insns` / `-max-blocks` | 24 / 8 | maximum size of a copied region |
| `--partial-inline-min-count` | BOLT hot threshold | minimum execution count of a call site |
| `--partial-inline-coverage` | 99 | share of the eligible fast-path calls to cover, hottest first |
| `--partial-inline-frame-elision` | on | allow eliding the callee's stack frame |
| `--print-partial-inline` | off | print the transformed functions |

`-v=1` lists every transformed call site, `-v=2` also why callees were
rejected. The options are documented in BOLT's command-line reference and in
`bolt/docs/PartialInlining.md` (both added by the patch).

## Reproducing the evaluation

Requires Docker on an AArch64 Linux host or Apple silicon. Either download the
prebuilt image from the [latest release](https://github.com/ElyasEbrahim/bolt-partial-inlining/releases/latest)
and `docker load` it, or build it:

```bash
make image          # upstream and patched BOLT, BOLT test suite for both, workloads
make check-bolt     # results/check-bolt/: test results of both builds, compared
make experiments    # complete evaluation in one run (about 50 min), updates results/
make x86-validate   # functional validation on x86-64 under emulation
```

The base image is pinned by digest, but the packages installed into it (the
Ubuntu archive and clang from apt.llvm.org) are not: an image built at a later
date can contain a newer compiler than the one behind `results/`. The release
image is the exact environment of the published results; its ID is recorded in
`results/environment.txt`.

`make experiments` runs [`scripts/run_experiments.sh`](scripts/run_experiments.sh)
in the image: it builds all BOLT variants from instrumentation profiles,
verifies that `llvm-bolt` without `--partial-inline` produces byte-identical
binaries to upstream, times all variants with interleaved rounds and
per-run output verification, counts executed instructions with valgrind and
writes [`results/REPORT.md`](results/REPORT.md). The training runs disable
address space layout randomization (`setarch -R`) so that profiles and BOLT
outputs are reproducible, and every measured run executes a fresh copy of the
binary at the same path, so that the result does not depend on a variant's
file name. The container therefore needs `--security-opt seccomp=unconfined`
and a tmpfs at `/stage`, both set by the Makefile.

## Testing

The patch adds seven lit tests to `bolt/test/` (run them with
`ninja check-bolt`):

| Test | Checks |
|---|---|
| `AArch64/partial-inline-frameless.s` | copied fast path, slow-path call, profile update, callee unchanged |
| `AArch64/partial-inline-frame-elision.s` | prologue/epilogue elision and callee-saved register renaming |
| `AArch64/partial-inline-reject.s` | ten callees that must not be transformed |
| `AArch64/partial-inline-sites.s` | tail-call sites, profile models, thresholds |
| `AArch64/partial-inline-pauth.s` | pointer authentication and BTI |
| `X86/partial-inline.s` | x86-64 frameless fast paths with `endbr64` |
| `runtime/AArch64/partial-inline.c` | end-to-end build, profile, optimize and run, with and without `-mbranch-protection=standard` |

## Limitations

Fast paths that call other functions, contain loops, use the stack, or store to
memory or overwrite an argument register before the fast/slow decision are not
inlined. Stack frame elision is implemented for AArch64 only. BOLT profiles are
context-insensitive, which the default worst-case model compensates for
conservatively. See [`docs/design.md`](docs/design.md#7-limitations-and-future-work)
for details and future work.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md).

## License

Apache License v2.0 with LLVM Exceptions, the license of the LLVM project; see
[LICENSE](LICENSE). The evaluation downloads and builds third-party software
under its own license: SQLite (public domain), Lua (MIT), CPython (PSF
License), zstd (BSD or GPLv2), jq (MIT; bundled Oniguruma: BSD) and libxml2
(MIT).
