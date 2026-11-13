# Evaluation report

Metric: user CPU time of the whole process. All variants of a workload run once per round in rotated order; speedup = median over rounds of t(bolt)/t(variant) (paired), with a 95% bootstrap confidence interval; p = two-sided Wilcoxon signed-rank test of `bolt-pi` against `bolt`. Every run's output was verified against the original binary.

## Speedup over the BOLT baseline

`bolt-copy` is a byte-identical copy of `bolt` (A/A control): it shows the size of differences the measurement reports when there is none.

| workload | class | rounds | bolt [s] | bolt-copy | bolt-pi | bolt-pi-avg | bolt-pi-nofe | bolt-inl | bolt-inl-pi | p (bolt-pi) |
|---|---|---:|---:|---|---|---|---|---|---|---:|
| bufwrite | target | 15 | 0.953 | 0.999 [0.996, 1.002] | 1.003 [1.000, 1.007] | 1.001 [0.997, 1.006] | 0.999 [0.993, 1.001] | 0.997 [0.995, 1.000] | 1.000 [1.000, 1.008] | 0.14 |
| memo | target | 15 | 0.763 | 0.998 [0.995, 1.003] | 1.018 [1.014, 1.020] | 1.021 [1.019, 1.025] | 1.001 [0.997, 1.005] | 0.995 [0.992, 0.997] | 1.021 [1.017, 1.026] | 6.1e-05 |
| trace | target | 15 | 0.404 | 0.999 [0.996, 1.006] | 1.663 [1.657, 1.679] | 1.672 [1.665, 1.685] | 1.669 [1.662, 1.680] | 1.001 [0.995, 1.005] | 1.665 [1.657, 1.679] | 6.1e-05 |
| pool | target | 15 | 0.376 | 1.003 [1.001, 1.007] | 0.953 [0.949, 0.957] | 0.955 [0.950, 0.958] | 1.029 [1.025, 1.033] | 1.029 [1.025, 1.030] | 0.953 [0.948, 0.961] | 6.1e-05 |
| mixed | adversarial | 15 | 0.353 | 1.005 [0.999, 1.007] | 2.728 [2.707, 2.748] | 2.436 [2.421, 2.457] | 2.736 [2.704, 2.757] | 1.153 [1.144, 1.165] | 2.730 [2.708, 2.744] | 6.1e-05 |
| memo-lowhit | neutral | 15 | 3.127 | 0.998 [0.988, 1.007] | 1.001 [0.999, 1.019] | 1.001 [0.995, 1.021] | 0.997 [0.981, 1.009] | 0.992 [0.981, 1.005] | 0.995 [0.983, 1.001] | 0.42 |
| unsafe | neutral | 15 | 0.269 | 1.002 [0.994, 1.006] | 0.999 [0.991, 1.002] | 0.998 [0.993, 1.001] | 0.998 [0.990, 1.007] | 1.643 [1.630, 1.649] | 1.644 [1.632, 1.652] | 0.42 |
| compute | neutral | 15 | 0.303 | 0.997 [0.992, 1.002] | 1.003 [0.990, 1.009] | 0.995 [0.990, 1.002] | 0.999 [0.989, 1.007] | 0.998 [0.993, 1.016] | 1.002 [0.995, 1.007] | 1 |
| sqlite | real | 30 | 0.937 | 1.004 [0.989, 1.010] | 1.002 [0.996, 1.007] | 0.993 [0.988, 1.003] | 0.996 [0.986, 1.005] | 0.994 [0.988, 1.001] | 0.990 [0.974, 1.001] | 0.63 |
| lua | real | 30 | 1.360 | 0.990 [0.983, 1.001] | 1.002 [0.995, 1.009] | 0.999 [0.989, 1.003] | 0.997 [0.983, 1.007] | 1.006 [1.000, 1.013] | 0.990 [0.976, 0.995] | 0.76 |
| cpython | real | 30 | 1.037 | 1.002 [0.997, 1.005] | 1.002 [0.997, 1.005] | 1.002 [0.994, 1.007] | 0.998 [0.991, 1.003] | 0.991 [0.988, 0.997] | 1.005 [1.001, 1.009] | 0.6 |
| zstd-compress | real | 30 | 0.457 | 1.005 [0.991, 1.016] | 0.992 [0.986, 1.025] | 1.005 [0.996, 1.025] | 1.001 [0.992, 1.028] | 0.998 [0.990, 1.014] | 0.996 [0.986, 1.013] | 0.89 |
| zstd-decompress | real | 30 | 0.340 | 1.001 [0.997, 1.012] | 1.001 [0.993, 1.010] | 1.002 [0.995, 1.010] | 1.005 [0.996, 1.011] | 1.005 [0.990, 1.015] | 1.005 [0.988, 1.010] | 0.76 |
| jq | real | 30 | 1.155 | 1.000 [0.983, 1.009] | 1.070 [1.060, 1.072] | 1.079 [1.073, 1.093] | 1.061 [1.056, 1.071] | 1.094 [1.093, 1.105] | 1.122 [1.115, 1.128] | 1.9e-09 |
| libxml2 | real | 30 | 0.542 | 1.010 [0.990, 1.020] | 1.009 [0.992, 1.019] | 1.005 [0.993, 1.016] | 1.011 [0.995, 1.030] | 1.001 [0.988, 1.010] | 0.994 [0.983, 1.013] | 0.54 |

## Partial inlining without trivial callees

`bolt-pi-skip` is `bolt-pi` with the named callees excluded (`-partial-inline-skip`): trivial functions that BOLT's existing `-inline-all` inlines as well. The difference to `bolt` is the share that only partial inlining achieves.

| workload | excluded | bolt-pi | bolt-pi-skip | bolt-inl | bolt-inl-pi | calls avoided bolt-pi | calls avoided bolt-pi-skip | p (bolt-pi-skip) |
|---|---|---|---|---|---|---:|---:|---:|
| jq | `jv_get_kind` | 1.070 [1.060, 1.072] | 1.023 [1.005, 1.033] | 1.094 [1.093, 1.105] | 1.122 [1.115, 1.128] | 26.40% | 8.67% | 8.9e-05 |

## Executed instructions (valgrind, smaller inputs; change vs. bolt)

All instructions of the process; every variant is executed from the same path (see scripts/icount.py).

| workload | bolt [instructions] | orig | bolt-pi | bolt-pi-nofe | bolt-inl | bolt-inl-pi |
|---|---:|---:|---:|---:|---:|---:|
| bufwrite | 138,318,069 | +2.17% | -23.85% | +0.00% | -0.00% | -23.85% |
| memo | 81,011,309 | +2.34% | -16.28% | +0.00% | -0.13% | -16.40% |
| trace | 75,098,604 | -0.00% | -15.98% | -15.98% | -0.00% | -15.98% |
| pool | 88,102,221 | +2.27% | -24.97% | -4.54% | -4.54% | -24.97% |
| mixed | 46,300,637 | +1.30% | -12.96% | -12.96% | -5.18% | -20.73% |
| memo-lowhit | 180,335,983 | -0.00% | +0.00% | +0.00% | -0.54% | -0.54% |
| unsafe | 42,129,278 | -0.00% | +0.00% | +0.00% | -9.50% | -9.50% |
| compute | 79,632,300 | -0.00% | -0.00% | -0.00% | +0.00% | +0.00% |
| sqlite | 1,175,824,455 | +0.83% | -0.06% | -0.03% | -0.07% | -0.10% |
| lua | 3,127,950,744 | +1.37% | -0.41% | -0.15% | -0.26% | -0.54% |
| cpython | 2,628,610,019 | +0.33% | -0.28% | -0.07% | -0.10% | -0.32% |
| zstd-compress | 945,884,181 | -0.00% | +0.00% | +0.00% | -0.00% | -0.00% |
| zstd-decompress | 331,355,307 | -0.12% | -0.00% | -0.00% | -0.00% | -0.00% |
| jq | 1,681,099,979 | +0.72% | -1.97% | -1.26% | -2.07% | -2.86% |
| libxml2 | 485,579,990 | +1.13% | -1.51% | -0.14% | -0.28% | -1.67% |

## pool: analysis of the slowdown (15 rounds per table)

`hw-*` are hand-written variants of the loop (`scripts/pool_loop.py`); speedups are relative to `bolt` of the same table.

### Block orders, single callees, LTO; hand-written loops that mirror BOLT outputs

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3826 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3822 | 1.001 [0.994, 1.002] | 0.85 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4026 | 0.950 [0.947, 0.956] | 6.1e-05 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.3748 | 1.019 [1.014, 1.029] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3726 | 1.027 [1.016, 1.031] | 0.0084 |
| pa-norb-bolt | baseline, original block order | 0.3829 | 0.999 [0.991, 1.008] | 0.42 |
| pa-norb-pi | partial inlining, original block order | 0.3368 | 1.133 [1.126, 1.139] | 6.1e-05 |
| pa-cache-bolt | baseline, `-reorder-blocks=cache` | 0.3846 | 0.995 [0.984, 0.998] | 0.064 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3746 | 1.021 [1.006, 1.025] | 0.01 |
| pa-lto | compiler LTO (inlines both functions) | 0.3394 | 1.128 [1.126, 1.132] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3835 | 0.999 [0.994, 1.002] | 0.39 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4033 | 0.948 [0.942, 0.950] | 6.1e-05 |
| hw-norb | hand-written loop of `pa-norb-pi` | 0.3372 | 1.130 [1.125, 1.136] | 6.1e-05 |
| hw-cache | hand-written loop of `pa-cache-pi` | 0.3737 | 1.023 [1.017, 1.029] | 6.1e-05 |

### Instructions between the two inlined regions

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3817 | - | - |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3834 | 0.998 [0.995, 0.999] | 0.048 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.3837 | 0.995 [0.992, 1.003] | 0.23 |
| hw-short2 | `hw-straight`, 2 instructions fewer between the regions | 0.4667 | 0.818 [0.815, 0.827] | 6.1e-05 |
| hw-short1 | `hw-straight`, 1 instruction fewer (no register copy) | 0.4494 | 0.851 [0.846, 0.856] | 6.1e-05 |
| hw-samebase | `hw-straight`, same base register in both regions | 0.4052 | 0.944 [0.931, 0.950] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4011 | 0.953 [0.944, 0.956] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3780 | 1.008 [1.003, 1.019] | 0.0067 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3590 | 1.068 [1.059, 1.076] | 6.1e-05 |
| hw-gap+3 | `hw-straight`, 3 nops between the regions | 0.3689 | 1.033 [1.030, 1.046] | 6.1e-05 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.3545 | 1.076 [1.069, 1.089] | 6.1e-05 |
| hw-gap+5 | `hw-straight`, 5 nops between the regions | 0.4661 | 0.820 [0.817, 0.825] | 6.1e-05 |
| hw-gap+6 | `hw-straight`, 6 nops between the regions | 0.3573 | 1.071 [1.065, 1.077] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3509 | 1.085 [1.084, 1.098] | 6.1e-05 |
| hw-gap+16 | `hw-straight`, 16 nops between the regions | 0.3520 | 1.084 [1.082, 1.092] | 6.1e-05 |
| hw-tail+4 | `hw-straight`, 4 nops after the second region | 0.3619 | 1.056 [1.047, 1.060] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.3798 | 1.014 [0.901, 1.060] | 0.56 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3813 | 0.999 [0.932, 1.089] | 0.64 |

### Code placement

Each loop shifted by 0, 4, ..., 60 bytes (nops in front of the loop that are not executed); speedup vs bolt per placement.

| loop | min | median | max | all 16 placements |
|---|---:|---:|---:|---|
| hw-base | 0.991 | 1.009 | 1.023 | 0.997 1.020 0.991 1.017 0.998 1.023 1.001 1.020 1.000 1.022 1.002 1.020 0.998 1.021 0.998 1.016 |
| hw-straight | 0.947 | 0.955 | 0.963 | 0.957 0.947 0.954 0.950 0.959 0.950 0.950 0.953 0.949 0.958 0.951 0.960 0.963 0.958 0.956 0.962 |

### Build with `slot = i & (w - 1)` (no random number generator in the loop)

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| orig | compiler output | 0.3488 | 0.985 [0.971, 1.000] | 0.0054 |
| bolt |  | 0.3450 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3446 | 0.998 [0.988, 1.006] | 0.72 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4300 | 0.802 [0.796, 0.808] | 6.1e-05 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.4005 | 0.857 [0.833, 0.915] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3440 | 0.993 [0.985, 1.018] | 0.52 |
| pa-norb-pi | partial inlining, original block order | 0.3278 | 1.050 [1.037, 1.072] | 0.0084 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3756 | 0.915 [0.913, 0.926] | 6.1e-05 |
| pa-lto | compiler LTO (inlines both functions) | 0.1095 | 3.143 [3.116, 3.173] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3472 | 0.987 [0.984, 0.998] | 0.035 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.4356 | 0.786 [0.783, 0.792] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4282 | 0.803 [0.799, 0.811] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3899 | 0.881 [0.877, 0.891] | 6.1e-05 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3106 | 1.104 [1.068, 1.128] | 0.01 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.2559 | 1.345 [1.318, 1.359] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3761 | 0.914 [0.897, 0.961] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.3082 | 1.122 [0.881, 1.188] | 0.76 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3594 | 0.935 [0.878, 1.101] | 0.11 |

## What the pass did (bolt-pi)

| workload | callees with fast region | sites | with frame elision | tail-call sites | insns copied | regs renamed | fast-path calls avoided (% of direct calls) |
|---|---:|---:|---:|---:|---:|---:|---:|
| bufwrite | 1 | 1 | 1 | 0 | 10 | 2 | 29992676 (99.93%) |
| memo | 1 | 1 | 1 | 0 | 10 | 2 | 19498383 (95.11%) |
| trace | 1 | 2 | 0 | 0 | 8 | 0 | 60000000 (100.00%) |
| pool | 2 | 2 | 1 | 0 | 16 | 1 | 39999743 (100.00%) |
| mixed | 2 | 3 | 0 | 0 | 15 | 0 | 25500000 (70.83%) |
| memo-lowhit | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0.00%) |
| unsafe | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0.00%) |
| compute | 1 | 1 | 0 | 0 | 3 | 0 | 1 (5.00%) |
| sqlite | 7 | 8 | 3 | 0 | 96 | 7 | 970227 (4.07%) |
| lua | 11 | 14 | 4 | 2 | 151 | 3 | 6914362 (12.66%) |
| cpython | 15 | 14 | 5 | 1 | 158 | 3 | 2496232 (4.55%) |
| zstd-compress | 5 | 5 | 0 | 0 | 29 | 0 | 819 (1.24%) |
| zstd-decompress | 5 | 5 | 0 | 0 | 29 | 0 | 819 (1.24%) |
| jq | 9 | 21 | 5 | 1 | 99 | 4 | 52156991 (26.40%) |
| libxml2 | 6 | 7 | 5 | 0 | 95 | 0 | 4866953 (25.72%) |

## Profile-estimated dynamic effect (BOLT dyno-stats, bolt-pi vs bolt)

| workload | executed instructions | all function calls | taken branches | executed load instructions | executed store instructions |
|---|---:|---:|---:|---:|---:|
| bufwrite | -23.90% | -99.90% | -0.02% | -57.12% | -66.64% |
| memo | -16.84% | -95.11% | -1.91% | -48.12% | -95.11% |
| trace | -16.00% | -100.00% | +0.00% | +0.00% | +0.00% |
| pool | -25.00% | -100.00% | +0.00% | -33.33% | -30.00% |
| mixed | -8.12% | -70.83% | +31.25% | +6.25% | +0.00% |
| memo-lowhit | +0.00% | +0.00% | +0.00% | +0.00% | +0.00% |
| unsafe | +0.00% | +0.00% | +0.00% | +0.00% | +0.00% |
| compute | -0.00% | -3.45% | +0.00% | +0.00% | +0.00% |
| sqlite | -0.14% | -2.20% | +0.18% | -0.09% | -0.28% |
| lua | -1.02% | -10.15% | +0.00% | -0.70% | -1.58% |
| cpython | -0.62% | -3.34% | +0.00% | -0.75% | -1.33% |
| zstd-compress | -0.00% | -0.65% | +0.00% | +0.00% | +0.00% |
| zstd-decompress | -0.00% | -0.65% | +0.00% | +0.00% | +0.00% |
| jq | -2.97% | -21.81% | +1.71% | -1.29% | -1.62% |
| libxml2 | -2.39% | -18.61% | +0.01% | -2.59% | -5.53% |

## Code size and BOLT processing time

| workload | .text bolt [B] | .text bolt-pi [B] | growth | llvm-bolt time bolt [s] | bolt-pi [s] |
|---|---:|---:|---:|---:|---:|
| bufwrite | 1020 | 984 | -3.53% | 0.0 | 0.01 |
| memo | 812 | 816 | +0.49% | 0.0 | 0.01 |
| trace | 808 | 832 | +2.97% | 0.0 | 0.01 |
| pool | 1000 | 1092 | +9.20% | 0.0 | 0.01 |
| mixed | 884 | 916 | +3.62% | 0.0 | 0.01 |
| memo-lowhit | 812 | 812 | +0.00% | 0.0 | 0.01 |
| unsafe | 1032 | 1032 | +0.00% | 0.0 | 0.01 |
| compute | 1188 | 1228 | +3.37% | 0.0 | 0.01 |
| sqlite | 631968 | 632172 | +0.03% | 0.36 | 0.38 |
| lua | 131136 | 131708 | +0.44% | 0.1 | 0.1 |
| cpython | 1227976 | 1229104 | +0.09% | 1.11 | 1.17 |
| zstd-compress | 65736 | 65896 | +0.24% | 0.08 | 0.08 |
| zstd-decompress | 65736 | 65896 | +0.24% | 0.08 | 0.08 |
| jq | 133408 | 133728 | +0.24% | 0.12 | 0.13 |
| libxml2 | 101288 | 101856 | +0.56% | 0.15 | 0.16 |

## Rejection reasons (callees of hot call sites without a usable fast region)

| workload | not-simple | no-profile | entry-not-copyable | no-fast-exit | stack-access | frame-mismatch | side-effect | reg-clobber | no-scratch | too-large | cold-fast-path |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| bufwrite | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| memo | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| trace | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| pool | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| mixed | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| memo-lowhit | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| unsafe | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 |
| compute | 8 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| sqlite | 17 | 0 | 7 | 30 | 1 | 0 | 4 | 2 | 0 | 3 | 7 |
| lua | 8 | 0 | 11 | 18 | 1 | 0 | 1 | 4 | 0 | 1 | 2 |
| cpython | 16 | 0 | 11 | 45 | 0 | 1 | 4 | 4 | 0 | 1 | 6 |
| zstd-compress | 5 | 0 | 1 | 18 | 0 | 0 | 4 | 0 | 0 | 0 | 1 |
| zstd-decompress | 5 | 0 | 1 | 18 | 0 | 0 | 4 | 0 | 0 | 0 | 1 |
| jq | 5 | 0 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| libxml2 | 5 | 0 | 3 | 27 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
