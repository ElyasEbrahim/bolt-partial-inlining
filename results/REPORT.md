# Evaluation report

Metric: user CPU time of the whole process. All variants of a workload run once per round in rotated order; speedup = median over rounds of t(bolt)/t(variant) (paired), with a 95% bootstrap confidence interval; p = two-sided Wilcoxon signed-rank test of `bolt-pi` against `bolt`. Every run's output was verified against the original binary.

## Speedup over the BOLT baseline

`bolt-copy` is a byte-identical copy of `bolt` (A/A control): it shows the size of differences the measurement reports when there is none.

| workload | class | rounds | bolt [s] | bolt-copy | bolt-pi | bolt-pi-avg | bolt-pi-nofe | bolt-inl | bolt-inl-pi | p (bolt-pi) |
|---|---|---:|---:|---|---|---|---|---|---|---:|
| bufwrite | target | 15 | 0.937 | 1.001 [1.000, 1.004] | 1.024 [1.014, 1.033] | 1.025 [1.012, 1.031] | 1.002 [0.997, 1.003] | 1.000 [0.996, 1.005] | 1.027 [1.018, 1.033] | 0.00018 |
| memo | target | 15 | 0.756 | 0.999 [0.996, 1.006] | 1.067 [1.056, 1.078] | 1.071 [1.069, 1.074] | 0.997 [0.992, 1.005] | 0.990 [0.985, 0.992] | 1.072 [1.062, 1.077] | 0.00012 |
| trace | target | 15 | 0.400 | 1.001 [0.996, 1.004] | 1.660 [1.655, 1.666] | 1.658 [1.649, 1.665] | 1.655 [1.641, 1.668] | 1.000 [0.996, 1.007] | 1.666 [1.649, 1.671] | 6.1e-05 |
| pool | target | 15 | 0.375 | 1.000 [0.998, 1.004] | 0.951 [0.948, 0.955] | 0.952 [0.947, 0.953] | 1.028 [1.025, 1.030] | 1.027 [1.017, 1.032] | 0.949 [0.948, 0.953] | 0.0084 |
| lookup | target | 15 | 0.473 | 0.999 [0.996, 1.003] | 1.466 [1.458, 1.471] | 1.462 [1.452, 1.471] | 1.457 [1.451, 1.461] | 1.613 [1.607, 1.619] | 1.609 [1.605, 1.615] | 6.1e-05 |
| chain | target | 15 | 0.579 | 1.003 [0.997, 1.006] | 2.569 [2.563, 2.580] | 2.565 [2.543, 2.576] | 2.566 [2.550, 2.572] | 2.593 [2.555, 2.598] | 2.581 [2.577, 2.594] | 6.1e-05 |
| mixed | adversarial | 15 | 0.355 | 1.001 [0.999, 1.008] | 2.734 [2.730, 2.751] | 2.457 [2.442, 2.472] | 2.743 [2.733, 2.756] | 1.158 [1.146, 1.165] | 2.750 [2.732, 2.765] | 6.1e-05 |
| memo-lowhit | neutral | 15 | 3.276 | 0.999 [0.998, 1.000] | 1.001 [0.998, 1.003] | 1.002 [0.998, 1.003] | 1.002 [0.998, 1.005] | 1.001 [0.998, 1.005] | 1.001 [0.996, 1.003] | 0.42 |
| lookup-deep | neutral | 15 | 0.339 | 1.002 [0.997, 1.008] | 1.001 [0.992, 1.004] | 1.000 [0.993, 1.003] | 1.003 [0.996, 1.005] | 1.521 [1.506, 1.525] | 1.517 [1.501, 1.522] | 0.93 |
| unsafe | neutral | 15 | 0.332 | 0.998 [0.996, 0.999] | 1.001 [0.997, 1.003] | 1.001 [0.999, 1.002] | 0.999 [0.995, 1.001] | 0.997 [0.996, 1.005] | 1.000 [0.998, 1.006] | 0.8 |
| compute | neutral | 15 | 0.311 | 0.998 [0.992, 1.003] | 0.999 [0.997, 1.004] | 1.000 [0.997, 1.009] | 0.998 [0.994, 1.003] | 0.999 [0.991, 1.003] | 0.999 [0.996, 1.003] | 0.6 |
| sqlite | real | 30 | 0.965 | 1.004 [0.998, 1.009] | 1.001 [0.997, 1.008] | 1.007 [0.997, 1.015] | 0.999 [0.993, 1.004] | 1.010 [1.000, 1.012] | 1.009 [1.001, 1.014] | 0.67 |
| lua | real | 30 | 1.406 | 0.996 [0.992, 1.001] | 1.008 [1.002, 1.010] | 1.005 [1.002, 1.008] | 0.998 [0.992, 1.002] | 1.006 [1.005, 1.012] | 1.008 [1.005, 1.018] | 1.4e-05 |
| cpython | real | 30 | 1.066 | 0.997 [0.990, 1.004] | 1.004 [0.999, 1.010] | 1.009 [1.005, 1.012] | 0.996 [0.993, 1.000] | 1.000 [0.994, 1.004] | 1.007 [1.002, 1.010] | 0.011 |
| zstd-compress | real | 30 | 0.465 | 1.006 [0.996, 1.027] | 1.007 [0.991, 1.029] | 0.993 [0.985, 1.002] | 1.005 [0.992, 1.025] | 1.001 [0.990, 1.029] | 0.996 [0.985, 1.011] | 0.24 |
| zstd-decompress | real | 30 | 0.340 | 1.000 [0.988, 1.010] | 0.996 [0.982, 1.013] | 0.998 [0.990, 1.006] | 1.000 [0.990, 1.011] | 1.004 [0.996, 1.007] | 1.004 [0.997, 1.015] | 0.9 |
| jq | real | 30 | 1.369 | 0.997 [0.992, 1.004] | 1.124 [1.119, 1.128] | 1.118 [1.111, 1.124] | 1.110 [1.106, 1.116] | 1.163 [1.159, 1.166] | 1.181 [1.176, 1.187] | 1.9e-09 |
| libxml2 | real | 30 | 0.604 | 0.999 [0.984, 1.005] | 1.003 [0.982, 1.016] | 1.001 [0.993, 1.026] | 0.997 [0.987, 1.013] | 1.006 [0.990, 1.018] | 1.003 [0.988, 1.011] | 0.98 |
| clang | real | 30 | 11.701 | 1.001 [0.998, 1.005] | 1.015 [1.013, 1.017] | 1.016 [1.014, 1.019] | 1.009 [1.007, 1.013] | 1.006 [1.004, 1.007] | 1.015 [1.013, 1.018] | 9.3e-09 |

## Partial inlining without trivial callees

`bolt-pi-skip` is `bolt-pi` with the named callees excluded (`-partial-inline-skip`): trivial functions that BOLT's existing `-inline-all` inlines as well. The difference to `bolt` is the share that only partial inlining achieves.

| workload | excluded | bolt-pi | bolt-pi-skip | bolt-inl | bolt-inl-pi | calls avoided bolt-pi | calls avoided bolt-pi-skip | p (bolt-pi-skip) |
|---|---|---|---|---|---|---:|---:|---:|
| jq | `jv_get_kind` | 1.124 [1.119, 1.128] | 1.017 [1.009, 1.022] | 1.163 [1.159, 1.166] | 1.181 [1.176, 1.187] | 26.40% | 8.67% | 8.3e-07 |

## Branch relaxation

Upstream BOLT relaxes AArch64 branches with clusters by default since 2026-11-23 (`-relax-with-clusters`); all other variants use this default. `bolt-nocl` and `bolt-pi-nocl` are `bolt` and `bolt-pi` with the previous stub insertion (`-relax-with-clusters=false`). The fourth column compares `bolt-pi-nocl` with `bolt-nocl` (paired, same run); the instruction counts are relative to the baseline with the same relaxation.

| workload | bolt-nocl vs bolt | bolt-pi vs bolt | bolt-pi-nocl vs bolt-nocl | p | instructions bolt-nocl vs bolt | instructions bolt-pi vs bolt | instructions bolt-pi-nocl vs bolt-nocl |
|---|---|---|---|---:|---:|---:|---:|
| sqlite | 1.006 [0.999, 1.013] | 1.001 [0.997, 1.008] | 1.005 [1.000, 1.010] | 0.047 | -0.87% | -0.06% | -0.06% |
| lua | 1.009 [1.003, 1.012] | 1.008 [1.002, 1.010] | 0.999 [0.997, 1.006] | 0.49 | -0.52% | -0.52% | -0.53% |
| cpython | 1.007 [1.003, 1.011] | 1.004 [0.999, 1.010] | 0.995 [0.989, 1.003] | 0.092 | -0.18% | -0.28% | -0.28% |
| zstd-compress | 0.999 [0.989, 1.014] | 1.007 [0.991, 1.029] | 1.007 [0.990, 1.024] | 0.31 | -0.00% | +0.59% | +0.59% |
| zstd-decompress | 1.004 [0.991, 1.016] | 0.996 [0.982, 1.013] | 0.993 [0.984, 0.999] | 0.1 | -0.09% | +0.00% | +0.00% |
| jq | 1.111 [1.105, 1.117] | 1.124 [1.119, 1.128] | 1.068 [1.064, 1.072] | 1.9e-09 | -5.19% | -3.34% | -1.97% |
| libxml2 | 0.995 [0.990, 1.008] | 1.003 [0.982, 1.016] | 1.000 [0.984, 1.018] | 0.81 | -0.14% | -1.48% | -1.51% |
| clang | 1.003 [1.002, 1.004] | 1.015 [1.013, 1.017] | 1.014 [1.013, 1.015] | 1.9e-09 | -0.55% | -2.13% | -2.02% |

## Effect of the extensions

`bolt-pi-noext` is `bolt-pi` without fast paths through the first iteration of a loop and without saved registers (`-partial-inline-loops=false -partial-inline-save-regs=false`): the pass as in version 1.2.0. For the workloads that are not listed, both binaries are byte-identical: bufwrite, memo, trace, pool, mixed, memo-lowhit, lookup-deep, unsafe, compute, jq, libxml2.

| workload | bolt-pi-noext | bolt-pi | calls avoided noext | calls avoided bolt-pi | sites through a loop | sites with saved registers | instructions noext | instructions bolt-pi |
|---|---|---|---:|---:|---:|---:|---:|---:|
| lookup | 1.001 [0.998, 1.002] | 1.466 [1.458, 1.471] | 0.00% | 94.64% | 1 | 0 | +0.00% | -6.96% |
| chain | 1.002 [0.995, 1.010] | 2.569 [2.563, 2.580] | 0.00% | 98.44% | 0 | 1 | +0.00% | -7.90% |
| sqlite | 1.007 [0.997, 1.011] | 1.001 [0.997, 1.008] | 4.07% | 4.20% | 0 | 1 | -0.06% | -0.06% |
| lua | 1.004 [1.002, 1.009] | 1.008 [1.002, 1.010] | 12.66% | 15.45% | 1 | 3 | -0.40% | -0.52% |
| cpython | 1.002 [0.998, 1.008] | 1.004 [0.999, 1.010] | 4.54% | 4.69% | 1 | 2 | -0.27% | -0.28% |
| zstd-compress | 1.009 [0.989, 1.022] | 1.007 [0.991, 1.029] | 0.00% | 46.07% | 1 | 1 | +0.00% | +0.59% |
| zstd-decompress | 0.996 [0.990, 1.014] | 0.996 [0.982, 1.013] | 0.00% | 46.07% | 1 | 1 | +0.00% | +0.00% |
| clang | 1.012 [1.010, 1.016] | 1.015 [1.013, 1.017] | 19.68% | 22.09% | 59 | 220 | -1.80% | -2.13% |

## Executed instructions (valgrind, smaller inputs; change vs. bolt)

All instructions of the process; every variant is executed from the same path (see scripts/icount.py).

| workload | bolt [instructions] | orig | bolt-pi | bolt-pi-nofe | bolt-inl | bolt-inl-pi |
|---|---:|---:|---:|---:|---:|---:|
| bufwrite | 138,320,280 | +2.17% | -23.85% | +0.00% | -0.00% | -23.85% |
| memo | 81,011,324 | +2.34% | -16.28% | +0.00% | -0.13% | -16.40% |
| trace | 75,098,616 | -0.00% | -15.98% | -15.98% | -0.00% | -15.98% |
| pool | 88,102,239 | +2.27% | -24.97% | -4.54% | -4.54% | -24.97% |
| lookup | 43,134,393 | -0.00% | -6.96% | -6.96% | -9.24% | -9.24% |
| chain | 22,536,906 | -0.00% | -7.90% | -7.90% | -17.61% | -17.61% |
| mixed | 46,300,649 | +1.30% | -12.96% | -12.96% | -5.18% | -20.73% |
| memo-lowhit | 180,335,998 | -0.00% | +0.00% | +0.00% | -0.54% | -0.54% |
| lookup-deep | 17,014,552 | -0.00% | +0.00% | +0.00% | -9.21% | -9.21% |
| unsafe | 26,129,249 | -0.00% | +0.00% | +0.00% | -0.02% | -0.02% |
| compute | 79,632,328 | -0.00% | -0.00% | -0.00% | +0.00% | +0.00% |
| sqlite | 1,186,146,225 | -0.05% | -0.06% | -0.03% | -0.08% | -0.11% |
| lua | 3,144,449,225 | +0.84% | -0.52% | -0.15% | -0.25% | -0.73% |
| cpython | 2,635,385,363 | +0.15% | -0.28% | -0.06% | -0.10% | -0.45% |
| zstd-compress | 934,164,906 | +1.25% | +0.59% | +0.59% | -0.44% | -0.44% |
| zstd-decompress | 331,637,246 | -0.20% | +0.00% | +0.00% | -0.00% | -0.00% |
| jq | 1,773,215,087 | -4.51% | -3.34% | -2.69% | -3.84% | -4.58% |
| libxml2 | 486,276,807 | +0.99% | -1.48% | -0.14% | -0.28% | -1.64% |
| clang | 6,795,475,883 | +0.22% | -2.13% | -0.76% | -1.00% | -2.47% |

## pool: analysis of the slowdown (15 rounds per table)

`hw-*` are hand-written variants of the loop (`scripts/pool_loop.py`); speedups are relative to `bolt` of the same table.

### Block orders, single callees, LTO; hand-written loops that mirror BOLT outputs

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3820 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3822 | 1.000 [0.997, 1.002] | 0.98 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4027 | 0.949 [0.947, 0.954] | 0.00012 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.3749 | 1.021 [1.015, 1.023] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3717 | 1.025 [1.023, 1.033] | 6.1e-05 |
| pa-norb-bolt | baseline, original block order | 0.3822 | 0.998 [0.995, 1.003] | 0.72 |
| pa-norb-pi | partial inlining, original block order | 0.3364 | 1.137 [1.134, 1.139] | 6.1e-05 |
| pa-cache-bolt | baseline, `-reorder-blocks=cache` | 0.3827 | 0.999 [0.995, 1.002] | 0.19 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3741 | 1.022 [1.018, 1.025] | 6.1e-05 |
| pa-lto | compiler LTO (inlines both functions) | 0.3369 | 1.134 [1.133, 1.135] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3832 | 0.996 [0.994, 1.000] | 0.041 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4000 | 0.956 [0.951, 0.960] | 0.00031 |
| hw-norb | hand-written loop of `pa-norb-pi` | 0.3370 | 1.134 [1.130, 1.138] | 6.1e-05 |
| hw-cache | hand-written loop of `pa-cache-pi` | 0.3747 | 1.019 [1.015, 1.027] | 6.1e-05 |

### Instructions between the two inlined regions

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3817 | - | - |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3838 | 0.995 [0.991, 1.000] | 0.01 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.3827 | 0.996 [0.993, 1.000] | 0.03 |
| hw-short2 | `hw-straight`, 2 instructions fewer between the regions | 0.4656 | 0.819 [0.817, 0.823] | 6.1e-05 |
| hw-short1 | `hw-straight`, 1 instruction fewer (no register copy) | 0.4489 | 0.851 [0.849, 0.852] | 6.1e-05 |
| hw-samebase | `hw-straight`, same base register in both regions | 0.4045 | 0.942 [0.940, 0.949] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.3995 | 0.954 [0.951, 0.959] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3782 | 1.009 [1.006, 1.011] | 0.00012 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3587 | 1.065 [1.062, 1.067] | 6.1e-05 |
| hw-gap+3 | `hw-straight`, 3 nops between the regions | 0.3787 | 1.005 [1.001, 1.014] | 0.041 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.3541 | 1.079 [1.075, 1.080] | 0.0084 |
| hw-gap+5 | `hw-straight`, 5 nops between the regions | 0.4652 | 0.820 [0.818, 0.822] | 6.1e-05 |
| hw-gap+6 | `hw-straight`, 6 nops between the regions | 0.3575 | 1.067 [1.064, 1.069] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3523 | 1.083 [1.081, 1.085] | 6.1e-05 |
| hw-gap+16 | `hw-straight`, 16 nops between the regions | 0.3528 | 1.082 [1.077, 1.084] | 0.0084 |
| hw-tail+4 | `hw-straight`, 4 nops after the second region | 0.3619 | 1.055 [1.054, 1.056] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.4234 | 0.900 [0.883, 0.930] | 0.00018 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3906 | 0.972 [0.906, 1.067] | 0.36 |

### Code placement

Each loop shifted by 0, 4, ..., 60 bytes (nops in front of the loop that are not executed); speedup vs bolt per placement.

| loop | min | median | max | all 16 placements |
|---|---:|---:|---:|---|
| hw-base | 0.993 | 1.006 | 1.023 | 0.997 1.019 0.995 1.017 0.996 1.016 0.997 1.023 0.999 1.013 0.993 1.021 0.995 1.017 0.997 1.022 |
| hw-straight | 0.949 | 0.958 | 0.963 | 0.956 0.960 0.961 0.959 0.958 0.949 0.952 0.954 0.962 0.959 0.963 0.959 0.960 0.952 0.953 0.958 |

### Build with `slot = i & (w - 1)` (no random number generator in the loop)

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| orig | compiler output | 0.3443 | 0.987 [0.980, 0.993] | 6.1e-05 |
| bolt |  | 0.3402 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3401 | 0.998 [0.994, 1.008] | 0.93 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4240 | 0.801 [0.800, 0.804] | 6.1e-05 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.3749 | 0.912 [0.881, 0.918] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3400 | 0.998 [0.994, 1.005] | 0.52 |
| pa-norb-pi | partial inlining, original block order | 0.3240 | 1.052 [1.046, 1.054] | 6.1e-05 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3710 | 0.915 [0.913, 0.919] | 6.1e-05 |
| pa-lto | compiler LTO (inlines both functions) | 0.1080 | 3.152 [3.120, 3.168] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3437 | 0.990 [0.983, 0.996] | 6.1e-05 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.4329 | 0.783 [0.782, 0.787] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4252 | 0.799 [0.797, 0.803] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3859 | 0.881 [0.878, 0.883] | 6.1e-05 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3090 | 1.100 [1.072, 1.110] | 0.00018 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.2537 | 1.337 [1.332, 1.341] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3617 | 0.934 [0.925, 0.947] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.2892 | 1.173 [1.143, 1.189] | 0.00018 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3408 | 0.993 [0.920, 1.050] | 0.39 |

## Coverage on the real programs and what limits it

From the training profiles and `llvm-bolt -v=2`, without timing (`scripts/coverage.py`). *Entries*: transfers to the entry of another function in the instrumentation profile. *Unattributed*: entries whose caller the profile does not know, i.e. calls from functions that BOLT cannot rewrite and from outside the binary.

| program | entries | unattributed | direct calls at call sites the pass can transform | avoided | hottest callees of unattributed calls |
|---|---:|---:|---:|---:|---|
| sqlite | 44.85M | 23.4% | 23.82M | 1.00M (4.2%) | `sqlite3BtreeNext/1` 1.87M, `btreeParseCellPtr/1` 1.70M, `applyAffinity/1` 0.66M |
| lua | 104.18M | 42.2% | 54.61M | 8.44M (15.4%) | `luaH_getshortstr/1` 25.96M, `luaH_psetshortstr/1` 7.20M, `luaD_precall/1` 3.38M |
| cpython | 97.98M | 30.9% | 54.94M | 2.58M (4.7%) | `_PyFloat_FromDouble_ConsumeInputs/1` 7.20M, `_Py_Dealloc` 3.55M, `_PyObject_Free/1` 2.09M |
| zstd | 1.00M | 0.0% | 1.00M | 0.46M (46.1%) | `AIO_ReadPool_executeReadJob/1` 0.00M, `UTIL_freeFileNamesTable` 0.00M, `UTIL_allocateFileNamesTable` 0.00M |
| jq | 293.68M | 32.9% | 197.56M | 52.16M (26.4%) | `jv_get_kind` 36.94M, `stack_push` 26.28M, `jv_copy` 12.18M |
| libxml2 | 28.51M | 15.6% | 18.92M | 4.87M (25.7%) | `xmlXPathNextChildElement/1` 1.20M, `xmlXPathNodeSetAddUnique` 1.02M, `xmlXPathNextDescendantOrSelf` 0.90M |
| clang | 4810.01M | 9.2% | 4093.36M | 900.95M (22.0%) | `_ZN4llvm9KnownBitsD2Ev/1` 8.22M, `_ZN5clang12Preprocessor9CLK_LexerERS0_RNS_5TokenE/1` 7.01M, `_ZN4llvm21SimpleBitstreamCursor9JumpToBitEm/1` 6.95M |

### Callees of hot call sites without a usable fast region

Executions of the rejected callees as a share of the direct calls in the previous table, by reason, with the hottest callee. The shares are upper bounds: the execution count of a callee also contains indirect and unattributed calls.

| program | not-simple | no-fast-exit | entry-not-copyable | side-effect | cold-fast-path | too-large | stack-access | frame-mismatch | no-scratch |
|---|---|---|---|---|---|---|---|---|---|
| sqlite | 48.9% (`memcpy@PLT`) | 22.6% (`patternCompare`) | 3.5% (`computeCellSize`) | 12.4% (`sqlite3BtreeNext`) | 3.9% (`sqlite3VdbeMemSetText`) | 6.8% (`sqlite3VdbeRecordCompareWithSkip`) | 0.9% (`freeSpace`) | 0.6% (`releaseMemArray`) | - |
| lua | 16.6% (`realloc@PLT`) | 20.9% (`match`) | 15.7% (`luaM_free_`) | 6.6% (`luaD_precall`) | 7.5% (`singlematch`) | 18.5% (`luaH_psetshortstr`) | 1.5% (`lua_tonumberx`) | - | - |
| cpython | 35.8% (`_Py_NewReference`) | 41.1% (`_Py_Dealloc`) | 10.6% (`PyObject_Free`) | 3.4% (`_PyFrame_ClearExceptCode`) | 8.8% (`PyLong_FromLong`) | 2.4% (`unicodekeys_lookup_unicode`) | 1.6% (`_Py_dict_lookup`) | 0.1% (`maybe_small_long`) | - |
| zstd | 6.0% (`memmove@PLT`) | - | - | - | - | - | - | - | - |
| jq | 20.1% (`free@PLT`) | 20.3% (`jv_free`) | 19.9% (`jv_mem_free`) | - | - | 0.4% (`jvp_number_cmp`) | - | - | - |
| libxml2 | 8.8% (`memcpy@PLT`) | 45.8% (`xmlParserShrink`) | 3.5% (`xmlDictLookupHashed`) | 1.6% (`nodePop`) | - | 1.3% (`xmlIsID`) | - | 1.6% (`xmlNextChar`) | - |
| clang | 13.0% (`memcpy@PLT`) | 13.6% (`_ZL16computeKnownBitsPKN4llvm5ValueERKNS_5APIntERNS_9KnownBitsERKNS_13SimplifyQueryEj`) | 11.5% (`_ZN4llvm15AnalysisManagerINS_8FunctionEJEE13getResultImplEPNS_11AnalysisKeyERS1_`) | 5.1% (`_ZN4llvm15ValueHandleBase17RemoveFromUseListEv`) | 9.2% (`_ZN4llvm12DenseMapBaseINS_8densemap6detail15DenseMapStorageINS_6detail12DenseMapPairIPNS_4LoopES7_EEEES7_S7_NS_12DenseMapInfoIS7_vEES8_E24lookupOrInsertIntoBucketIRKS7_JEEESt4pairIPS8_bEOT_DpOT0_`) | 5.1% (`_ZN4llvm11xxh3_64bitsEPKhm`) | 4.7% (`_ZN4llvm21SimpleBitstreamCursor9ReadVBR64Ej`) | 3.1% (`_ZN4llvm12DenseMapBaseINS_8densemap6detail15DenseMapStorageINS_6detail12DenseMapPairISt4pairIPNS_11AnalysisKeyEPNS_8FunctionEEPNS4_21AnalysisResultConceptIS9_NS_15AnalysisManagerIS9_JEE11InvalidatorEEEEEEESB_SH_NS_12DenseMapInfoISB_vEESI_E24lookupOrInsertIntoBucketISB_JDnEEES6_IPSI_bEOT_DpOT0_`) | 0.0% (`_ZN12_GLOBAL__N_111CopyTracker14clobberRegUnitEN4llvm9MCRegUnitERKNS1_18TargetRegisterInfoERKNS1_15TargetInstrInfoEb`) |

### Region size limits and extensions

Calls avoided (share of the direct calls), BOLT's estimate of the executed instructions and code size, each relative to `bolt`, for `-partial-inline-max-insns` / `-max-blocks`. 24/8 is the default; *without extensions* is 24/8 with `-partial-inline-loops=false -partial-inline-save-regs=false`.

| program | without extensions | 16/6 | 24/8 | 32/8 | 40/12 | 64/16 |
|---|---|---|---|---|---|---|
| sqlite | 4.1%, -0.14%, +0.08% | 1.4%, -0.05%, +0.08% | 4.2%, -0.16%, +0.09% | 4.2%, -0.16%, +0.09% | 5.8%, -0.41%, +0.16% | 5.5%, -0.38%, +0.16% |
| lua | 12.7%, -1.02%, +0.42% | 10.0%, -0.68%, +0.19% | 15.4%, -1.27%, +0.56% | 16.4%, -1.25%, +0.66% | 18.6%, -1.51%, +1.27% | 18.6%, -1.51%, +1.27% |
| cpython | 4.5%, -0.62%, +0.01% | 4.2%, -0.61%, +0.01% | 4.7%, -0.63%, +0.05% | 4.7%, -0.63%, +0.06% | 4.7%, -0.63%, +0.06% | 4.7%, -0.63%, +0.06% |
| zstd | 0.0%, +0.00%, +0.00% | 0.0%, +0.00%, +0.00% | 46.1%, +0.30%, -0.04% | 46.1%, +0.30%, -0.04% | 0.0%, +0.00%, +0.00% | 0.0%, +0.00%, +0.00% |
| jq | 26.4%, -2.97%, +0.19% | 26.4%, -2.97%, +0.19% | 26.4%, -2.97%, +0.19% | 26.4%, -2.97%, +0.19% | 26.4%, -2.97%, +0.19% | 26.8%, -3.12%, +0.28% |
| libxml2 | 25.7%, -2.39%, +0.45% | 3.8%, -0.48%, +0.14% | 25.7%, -2.39%, +0.45% | 25.7%, -2.39%, +0.45% | 30.5%, -2.70%, +0.69% | 30.5%, -2.70%, +0.69% |
| clang | 19.6%, -1.64%, +0.34% | 19.6%, -1.60%, +0.30% | 22.0%, -1.93%, +0.40% | 22.4%, -1.95%, +0.42% | 23.2%, -2.06%, +0.47% | 24.3%, -2.23%, +0.54% |

## What the pass did (bolt-pi)

| workload | callees with fast region | sites | with frame elision | tail-call sites | through a loop | with saved regs | insns copied | regs renamed | fast-path calls avoided (% of direct calls) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| bufwrite | 1 | 1 | 1 | 0 | 0 | 0 | 10 | 2 | 29992676 (99.93%) |
| memo | 1 | 1 | 1 | 0 | 0 | 0 | 10 | 2 | 19498383 (95.11%) |
| trace | 1 | 2 | 0 | 0 | 0 | 0 | 8 | 0 | 60000000 (100.00%) |
| pool | 2 | 2 | 1 | 0 | 0 | 0 | 16 | 1 | 39999743 (100.00%) |
| lookup | 1 | 1 | 0 | 0 | 1 | 0 | 8 | 0 | 18928566 (94.64%) |
| chain | 1 | 1 | 0 | 0 | 0 | 1 | 4 | 0 | 19687500 (98.44%) |
| mixed | 2 | 3 | 0 | 0 | 0 | 0 | 15 | 0 | 25500000 (70.83%) |
| memo-lowhit | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0.00%) |
| lookup-deep | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0.00%) |
| unsafe | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0.00%) |
| compute | 1 | 1 | 0 | 0 | 0 | 0 | 3 | 0 | 1 (5.00%) |
| sqlite | 8 | 9 | 4 | 0 | 0 | 1 | 110 | 9 | 1000630 (4.20%) |
| lua | 16 | 18 | 7 | 2 | 1 | 3 | 223 | 7 | 8437234 (15.45%) |
| cpython | 18 | 17 | 7 | 2 | 1 | 2 | 200 | 3 | 2576854 (4.69%) |
| zstd-compress | 1 | 1 | 0 | 0 | 1 | 1 | 22 | 0 | 462476 (46.07%) |
| zstd-decompress | 1 | 1 | 0 | 0 | 1 | 1 | 22 | 0 | 462476 (46.07%) |
| jq | 9 | 21 | 5 | 1 | 0 | 0 | 99 | 4 | 52156991 (26.40%) |
| libxml2 | 8 | 7 | 5 | 0 | 0 | 0 | 95 | 0 | 4866953 (25.72%) |
| clang | 1144 | 2115 | 606 | 60 | 59 | 220 | 20087 | 606 | 904194577 (22.09%) |

## Profile-estimated dynamic effect (BOLT dyno-stats, bolt-pi vs bolt)

| workload | executed instructions | all function calls | taken branches | executed load instructions | executed store instructions |
|---|---:|---:|---:|---:|---:|
| bufwrite | -23.90% | -99.90% | -0.02% | -57.12% | -66.64% |
| memo | -16.84% | -95.11% | -1.91% | -48.12% | -95.11% |
| trace | -16.00% | -100.00% | +0.00% | +0.00% | +0.00% |
| pool | -25.00% | -100.00% | +0.00% | -33.33% | -30.00% |
| lookup | -10.75% | -94.64% | +8.23% | +3.92% | +0.00% |
| chain | -7.94% | -98.44% | -1.49% | +1.50% | +0.00% |
| mixed | -8.12% | -70.83% | +31.25% | +6.25% | +0.00% |
| memo-lowhit | +0.00% | +0.00% | +0.00% | +0.00% | +0.00% |
| lookup-deep | +0.00% | +0.00% | +0.00% | +0.00% | +0.00% |
| unsafe | +0.00% | +0.00% | +0.00% | +0.00% | +0.00% |
| compute | -0.00% | -3.45% | +0.00% | +0.00% | +0.00% |
| sqlite | -0.16% | -2.27% | +0.18% | -0.11% | -0.33% |
| lua | -1.27% | -12.38% | +0.13% | -0.99% | -2.27% |
| cpython | -0.63% | -3.45% | +0.00% | -0.77% | -1.36% |
| zstd-compress | +0.30% | -43.23% | +2.21% | +0.21% | +0.00% |
| zstd-decompress | +0.30% | -43.23% | +2.21% | +0.21% | +0.00% |
| jq | -2.97% | -21.81% | +1.71% | -1.29% | -1.62% |
| libxml2 | -2.39% | -18.61% | +0.01% | -2.59% | -5.53% |
| clang | -1.94% | -19.56% | +1.31% | -1.50% | -3.22% |

## Code size and BOLT processing time

| workload | .text bolt [B] | .text bolt-pi [B] | growth | llvm-bolt time bolt [s] | bolt-pi [s] |
|---|---:|---:|---:|---:|---:|
| bufwrite | 1116 | 1144 | +2.51% | 0.01 | 0.01 |
| memo | 884 | 952 | +7.69% | 0.0 | 0.01 |
| trace | 892 | 916 | +2.69% | 0.0 | 0.01 |
| pool | 1156 | 1192 | +3.11% | 0.01 | 0.01 |
| lookup | 960 | 1024 | +6.67% | 0.01 | 0.01 |
| chain | 744 | 804 | +8.06% | 0.0 | 0.01 |
| mixed | 956 | 1048 | +9.62% | 0.01 | 0.01 |
| memo-lowhit | 884 | 884 | +0.00% | 0.01 | 0.01 |
| lookup-deep | 1008 | 1008 | +0.00% | 0.0 | 0.01 |
| unsafe | 992 | 992 | +0.00% | 0.01 | 0.01 |
| compute | 1272 | 1312 | +3.14% | 0.01 | 0.01 |
| sqlite | 649956 | 650516 | +0.09% | 0.36 | 0.38 |
| lua | 135116 | 135876 | +0.56% | 0.09 | 0.1 |
| cpython | 1267972 | 1268612 | +0.05% | 1.11 | 1.19 |
| zstd-compress | 151980 | 151916 | -0.04% | 0.11 | 0.12 |
| zstd-decompress | 151980 | 151916 | -0.04% | 0.11 | 0.12 |
| jq | 138116 | 138372 | +0.19% | 0.12 | 0.13 |
| libxml2 | 108208 | 108700 | +0.45% | 0.15 | 0.16 |
| clang | 22814624 | 22903588 | +0.39% | 20.08 | 21.48 |

## Rejection reasons (callees of hot call sites without a usable fast region)

| workload | not-simple | no-profile | entry-not-copyable | no-fast-exit | stack-access | frame-mismatch | side-effect | reg-clobber | no-scratch | too-large | cold-fast-path |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| bufwrite | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| memo | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| trace | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| pool | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| lookup | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| chain | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| mixed | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| memo-lowhit | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| lookup-deep | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| unsafe | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| compute | 8 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| sqlite | 17 | 0 | 7 | 27 | 1 | 1 | 4 | 0 | 0 | 7 | 6 |
| lua | 8 | 0 | 11 | 14 | 1 | 0 | 1 | 0 | 0 | 4 | 2 |
| cpython | 16 | 0 | 11 | 38 | 1 | 1 | 8 | 0 | 0 | 3 | 7 |
| zstd-compress | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| zstd-decompress | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| jq | 5 | 0 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| libxml2 | 5 | 0 | 3 | 25 | 0 | 2 | 1 | 0 | 0 | 1 | 0 |
| clang | 243 | 0 | 801 | 885 | 164 | 168 | 234 | 0 | 1 | 159 | 379 |
