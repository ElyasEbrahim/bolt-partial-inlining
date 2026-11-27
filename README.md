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
  are provably dead at the call site,
* copies the first iteration of a loop on the fast path (a hash chain lookup
  that usually hits the first node) and leaves through its back edge,
* saves and restores an argument register that the fast path overwrites
  before it decides (`p = p->next`), and
* falls back to the original call on every other path. The copied region is
  side-effect free and re-executable up to the fast/slow decision, so the
  callee itself is left unchanged.

The patch applies to llvm-project
[`1be60cbf47e9`](https://github.com/llvm/llvm-project/commit/1be60cbf47e9b102a653f9cb54fc965fe71a1ec4)
(2026-11-25). AArch64 is fully supported; on x86-64 only fast paths that do
not touch the stack are inlined.

## Results

Apple M3 Max, Linux/AArch64 VM, clang 23 `-O2`/`-O3` without LTO, speedup of
`--partial-inline` over the BOLT baseline (`-reorder-blocks=ext-tsp
-reorder-functions=cdsort -split-functions ...`; for clang the options of the
in-tree Clang-BOLT rules), median of paired rounds with 95% confidence
interval. All numbers come from one run of `make experiments`; see
[`results/REPORT.md`](results/REPORT.md) and
[Section 5 of the design document](docs/design.md#5-experimental-evaluation).

| Workload | Pattern | Speedup | Executed instructions |
|---|---|---|---:|
| `mixed` | always-fast and always-slow call sites of one callee | **2.734x** [2.730, 2.751] | -13.0% |
| `chain` | callee overwrites its argument before it decides (saved register) | **2.569x** [2.563, 2.580] | -7.9% |
| `trace` | disabled tracing hook | **1.660x** [1.655, 1.666] | -16.0% |
| `lookup` | hash chain lookup, usually at the first node (first iteration of a loop) | **1.466x** [1.458, 1.471] | -7.0% |
| `memo` | memoization cache hit, callee not shrink-wrapped | **1.067x** [1.056, 1.078] | -16.3% |
| `bufwrite` | buffered writer, bound by a store-to-load chain | 1.024x [1.014, 1.033] | -23.9% |
| `pool` | free-list allocator, bound by store-to-load chains between the two inlined fast paths | 0.951x [0.948, 0.955] | -25.0% |
| `unsafe`, `memo-lowhit`, `lookup-deep`, `compute` | unsafe, too cold, or no calls | 0.999-1.001x | 0.00% |
| **clang** (Clang-BOLT, compiling SQLite and two LLVM files) | accessors of the AST and IR; 2,115 call sites, 606 with frame elision | **1.015x** [1.013, 1.017] | -2.1% |
| jq 1.8 | JSON processor, 26% of direct calls avoided | **1.124x** [1.119, 1.128] | -3.3% |
| jq 1.8, with the previous branch relaxation | the same, against the baseline with stub insertion | **1.068x** [1.064, 1.072] | -2.0% |
| jq 1.8, without the trivial callee `jv_get_kind` | share no existing BOLT pass achieves | **1.017x** [1.009, 1.022] | -0.9% |
| SQLite 3.54, Lua 5.5, CPython 3.14, zstd 1.5, libxml2 2.15 | real programs | 0.996-1.008x | +0.6% to -1.5% |
| A/A control | byte-identical copy of the baseline | 0.996-1.006x | - |

**clang** is the largest real program and the one BOLT itself is usually
evaluated on.
- **Setup:** clang is built and trained with the in-tree Clang-BOLT rules
  and timed on compiling three translation units that are not part of its
  training. In every run, the object files are byte-identical to those of
  the original clang.
- **What the pass does:** it removes an estimated 22% of clang's profiled
  direct calls, for 0.39% more hot code and 7% more BOLT processing time.
- **Compared with `-inline-all`:** BOLT's existing whole-function inliner
  gives 1.006x and grows the hot code by 20%. On top of it, the pass adds
  1.010x [1.008, 1.012].

**jq** gains most among the real programs, but mostly because upstream BOLT
changed its baseline.
- **The change:** on 2026-11-23, upstream BOLT made clustered branch
  relaxation its AArch64 default. jq's BOLT binary now executes 5.5% more
  instructions and runs 11% slower than with the previous stub insertion, and
  the pass removes part of that overhead.
- **With the previous relaxation,** the pass gives 1.068x, the same as
  version 1.3.1 measured (1.069x). Most of that comes from a one-instruction
  callee that `-inline-all` inlines as well.
- **clang** does not depend on the relaxation: 1.014x with the previous one.
  Lua's small gain (1.008x) does: 0.999x with the previous one.

The other real programs show no reliable change. Their hottest calls come
from interpreter loops that BOLT does not rewrite at all
([Section 5.6](docs/design.md#56-what-limits-the-pass-on-real-programs)).

Versions up to 1.3.1 measured zstd with an incomplete profile: the
decompression run of its training overwrote the profile of the compression
run, so BOLT optimized only decompression
([Section 5.7](docs/design.md#57-measurement-validity)). With the fixed
profile, the pass transforms one call site on the compression path that
costs more instructions than it saves (+0.6%), without a measurable change
in run time.

Without `--partial-inline`, the patched `llvm-bolt` writes byte-identical
binaries to upstream (36 of 36 comparisons, clang included), and no existing
BOLT test changes its result.

For `lookup` and `chain`, whose callees are small leaf functions without a
stack frame, BOLT's existing `-inline-all` is as fast or faster (1.613x and
2.593x): it inlines them as a whole. The support for loops and overwritten
registers matters for callees that `-inline-all` cannot inline, such as those
with a stack frame. In clang, 59 call sites run through the first iteration
of a loop and 220 save a register. Without the two extensions, the pass gives
1.012x instead of 1.015x there.

The pass can also lose: `pool` is 5% slower although it executes 25% fewer
instructions.
- **Why:** its two inlined fast paths store and reload the same fields in
  every loop iteration. On this core the run time of such a loop depends on
  the exact number of instructions between a store and its reload: 0.82x to
  1.08x when single instructions are added or removed.
- **The same kind of loop** also makes `memo` and `bufwrite` vary between
  runs. The same binaries measured 1.020x and 1.003x in the first,
  unpublished run of this version.
- The pass has no cost model for this; see
  [Section 5.5 of the design document](docs/design.md#55-analysis).

## Repository layout

| Path | Content |
|---|---|
| [`patches/`](patches/) | the LLVM patch (pass, target hooks, 9 lit tests, documentation) and the LLVM commit it applies to |
| [`docs/design.md`](docs/design.md) | design document: problem, design, correctness argument, implementation, evaluation, limitations |
| [`benchmarks/`](benchmarks/) | microbenchmarks and build scripts for SQLite, Lua, CPython, zstd, jq and libxml2 |
| [`scripts/`](scripts/) | profiling, BOLT variant generation, benchmarking, checks and reporting |
| [`results/`](results/) | the measurements of one complete evaluation run, see [`results/README.md`](results/README.md) |
| [`docker/`](docker/) | reproducible evaluation image and development environment |

## Getting started

### Build BOLT with the patch

```bash
git clone https://github.com/llvm/llvm-project.git && cd llvm-project
git checkout 1be60cbf47e9b102a653f9cb54fc965fe71a1ec4
git am /path/to/bolt-partial-inlining/patches/0001-*.patch
cmake -G Ninja -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=bolt -DLLVM_TARGETS_TO_BUILD="AArch64;X86"
ninja -C build bolt        # llvm-bolt, perf2bolt, merge-fdata, instrumentation runtime
```

LLVM at this commit needs CMake 3.31 or later.

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
`bolt/docs/PartialInlining.md` (both added by the patch). Two hidden options,
`--partial-inline-loops` and `--partial-inline-save-regs` (both on), switch
off the support for loops and for saved registers.

## Reproducing the evaluation

Requires Docker on an AArch64 Linux host or Apple silicon. Either download the
prebuilt image from the [latest release](https://github.com/ElyasEbrahim/bolt-partial-inlining/releases/latest)
and `docker load` it, or build it:

```bash
make image          # upstream and patched BOLT, BOLT test suite for both, workloads
make check-bolt     # results/check-bolt/: test results of both builds, compared
make experiments    # complete evaluation in one run (about 2.5 hours), updates results/
make x86-validate   # functional validation on x86-64 under emulation
```

The base image is pinned by digest, but the packages installed into it (the
Ubuntu archive and clang from apt.llvm.org) are not: an image built at a later
date can contain a newer compiler than the one behind `results/`. The release
image is the exact environment of the published results; its ID is recorded in
`results/environment.txt`. A rebuild from the same sources can show a
different image ID even when nothing changed, because Docker writes a new
image index for every build; to compare a rebuild with the release image, use
the platform manifest (`docker image ls --tree`) or the layers
(`docker image inspect --format '{{.RootFS.Layers}}'`).

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

The patch adds nine lit tests to `bolt/test/` (run them with
`ninja check-bolt`):

| Test | Checks |
|---|---|
| `AArch64/partial-inline-frameless.s` | copied fast path, slow-path call, profile update, callee unchanged |
| `AArch64/partial-inline-frame-elision.s` | prologue/epilogue elision and callee-saved register renaming |
| `AArch64/partial-inline-reject.s` | ten callees that must not be transformed |
| `AArch64/partial-inline-sites.s` | tail-call sites, profile models, thresholds |
| `AArch64/partial-inline-loop.s` | first iteration of a loop, back edge to the original call, profile bound for loop headers |
| `AArch64/partial-inline-save-regs.s` | overwritten argument register saved and restored, with frame elision and at tail calls |
| `AArch64/partial-inline-pauth.s` | pointer authentication and BTI |
| `X86/partial-inline.s` | x86-64 frameless fast paths with `endbr64` |
| `runtime/AArch64/partial-inline.c` | end-to-end build, profile, optimize and run, with and without `-mbranch-protection=standard` |

## Limitations

Fast paths that call other functions, use the stack, or store to memory before
the fast/slow decision are not inlined; of a loop only the first iteration is.
Stack frame elision and saving overwritten registers are implemented for
AArch64 only (general purpose registers). BOLT profiles are context-insensitive,
which the default worst-case model compensates for conservatively. Call sites
in functions that BOLT cannot rewrite, such as the interpreter loops of Lua,
CPython, jq and SQLite, are out of reach. See [`docs/design.md`](docs/design.md#7-limitations-and-future-work)
for details and future work.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md); the project follows the
[LLVM Community Code of Conduct](CODE_OF_CONDUCT.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md).

## License

Apache License v2.0 with LLVM Exceptions, the license of the LLVM project; see
[LICENSE](LICENSE). The evaluation downloads and builds third-party software
under its own license: SQLite (public domain), Lua (MIT), CPython (PSF
License), zstd (BSD or GPLv2), jq (MIT; bundled Oniguruma: BSD) and libxml2
(MIT).
