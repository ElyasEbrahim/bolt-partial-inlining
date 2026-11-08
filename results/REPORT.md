# Evaluation report

Metric: user CPU time of the whole process. All variants of a workload run once per round in rotated order; speedup = median over rounds of t(bolt)/t(variant) (paired), with a 95% bootstrap confidence interval; p = two-sided Wilcoxon signed-rank test of `bolt-pi` against `bolt`. Every run's output was verified against the original binary.

## Speedup over the BOLT baseline

`bolt-copy` is a byte-identical copy of `bolt` (A/A control): it shows the size of differences the measurement reports when there is none.

| workload | class | rounds | bolt [s] | bolt-copy | bolt-pi | bolt-pi-avg | bolt-pi-nofe | bolt-inl | bolt-inl-pi | p (bolt-pi) |
|---|---|---:|---:|---|---|---|---|---|---|---:|
| bufwrite | target | 15 | 0.958 | 0.998 [0.991, 1.011] | 1.004 [0.990, 1.014] | 1.002 [0.996, 1.006] | 0.999 [0.988, 1.017] | 0.998 [0.990, 1.005] | 1.007 [0.993, 1.009] | 0.72 |
| memo | target | 15 | 0.776 | 1.000 [0.982, 1.005] | 1.019 [1.008, 1.031] | 1.023 [1.011, 1.046] | 0.996 [0.991, 1.002] | 0.994 [0.975, 1.000] | 1.021 [1.005, 1.035] | 0.03 |
| trace | target | 15 | 0.403 | 0.997 [0.994, 1.001] | 1.668 [1.662, 1.673] | 1.661 [1.644, 1.669] | 1.667 [1.660, 1.674] | 0.999 [0.996, 1.004] | 1.662 [1.654, 1.670] | 6.1e-05 |
| pool | target | 15 | 0.388 | 1.000 [0.994, 1.010] | 0.952 [0.944, 0.961] | 0.952 [0.944, 0.964] | 1.030 [0.953, 1.033] | 1.029 [1.024, 1.034] | 0.952 [0.947, 0.957] | 6.1e-05 |
| mixed | adversarial | 15 | 0.364 | 1.002 [0.999, 1.006] | 2.720 [2.712, 2.742] | 2.442 [2.425, 2.447] | 2.727 [2.717, 2.739] | 1.150 [1.148, 1.155] | 2.728 [2.717, 2.745] | 6.1e-05 |
| memo-lowhit | neutral | 15 | 3.320 | 0.998 [0.994, 1.003] | 0.999 [0.994, 1.002] | 0.997 [0.994, 1.002] | 0.999 [0.991, 1.005] | 1.004 [1.002, 1.008] | 1.003 [1.001, 1.008] | 0.42 |
| unsafe | neutral | 15 | 0.277 | 0.999 [0.997, 1.010] | 1.005 [0.991, 1.009] | 1.001 [0.994, 1.009] | 0.999 [0.989, 1.002] | 1.639 [1.628, 1.653] | 1.641 [1.633, 1.654] | 0.52 |
| compute | neutral | 15 | 0.307 | 1.003 [0.995, 1.008] | 1.002 [0.998, 1.009] | 1.000 [0.994, 1.005] | 1.001 [0.997, 1.009] | 1.001 [0.998, 1.009] | 1.001 [0.995, 1.006] | 0.25 |
| sqlite | real | 30 | 0.943 | 1.003 [0.995, 1.010] | 1.005 [0.998, 1.013] | 1.002 [0.994, 1.012] | 1.001 [0.999, 1.018] | 1.010 [0.995, 1.014] | 1.006 [0.996, 1.013] | 0.18 |
| lua | real | 30 | 1.382 | 1.000 [0.995, 1.008] | 0.994 [0.990, 1.005] | 0.993 [0.989, 1.002] | 1.001 [0.989, 1.009] | 0.999 [0.992, 1.006] | 0.992 [0.985, 0.995] | 0.28 |
| cpython | real | 30 | 1.064 | 0.999 [0.987, 1.009] | 1.001 [0.992, 1.006] | 0.994 [0.991, 1.001] | 0.997 [0.987, 1.010] | 0.994 [0.990, 1.001] | 1.002 [0.993, 1.010] | 0.75 |
| zstd-compress | real | 30 | 0.461 | 0.997 [0.978, 1.015] | 0.991 [0.981, 1.018] | 0.993 [0.970, 1.007] | 1.014 [0.990, 1.024] | 1.017 [0.974, 1.029] | 0.998 [0.968, 1.012] | 0.69 |
| zstd-decompress | real | 30 | 0.344 | 0.998 [0.980, 1.026] | 0.983 [0.971, 1.005] | 0.980 [0.955, 1.009] | 0.994 [0.972, 1.015] | 0.987 [0.963, 1.009] | 0.987 [0.974, 1.006] | 0.26 |
| jq | real | 30 | 1.259 | 0.995 [0.975, 1.025] | 1.068 [1.060, 1.077] | 1.063 [1.047, 1.114] | 1.062 [1.034, 1.076] | 1.102 [1.086, 1.112] | 1.119 [1.092, 1.143] | 1.9e-09 |
| libxml2 | real | 30 | 0.580 | 1.006 [0.992, 1.024] | 1.000 [0.979, 1.021] | 1.011 [0.993, 1.014] | 1.002 [0.991, 1.012] | 0.998 [0.969, 1.015] | 0.994 [0.970, 1.028] | 0.92 |

## Partial inlining without trivial callees

`bolt-pi-skip` is `bolt-pi` with the named callees excluded (`-partial-inline-skip`): trivial functions that BOLT's existing `-inline-all` inlines as well. The difference to `bolt` is the share that only partial inlining achieves.

| workload | excluded | bolt-pi | bolt-pi-skip | bolt-inl | bolt-inl-pi | calls avoided bolt-pi | calls avoided bolt-pi-skip | p (bolt-pi-skip) |
|---|---|---|---|---|---|---:|---:|---:|
| jq | `jv_get_kind` | 1.068 [1.060, 1.077] | 1.022 [1.009, 1.025] | 1.102 [1.086, 1.112] | 1.119 [1.092, 1.143] | 26.40% | 8.67% | 0.00031 |

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
| sqlite | 1,175,824,388 | +0.83% | -0.06% | -0.03% | -0.07% | -0.10% |
| lua | 3,127,950,744 | +1.37% | -0.41% | -0.15% | -0.26% | -0.54% |
| cpython | 2,628,610,019 | +0.33% | -0.28% | -0.07% | -0.10% | -0.32% |
| zstd-compress | 945,884,181 | -0.00% | +0.00% | +0.00% | -0.00% | -0.00% |
| zstd-decompress | 331,355,307 | -0.12% | -0.00% | -0.00% | -0.00% | -0.00% |
| jq | 1,681,099,979 | +0.72% | -1.97% | -1.26% | -2.07% | -2.86% |
| libxml2 | 485,579,990 | +1.13% | -1.51% | -0.14% | -0.28% | -1.67% |

## pool: layout interaction analysis (15 rounds)

| variant | median [s] | speedup vs bolt [95% CI] | p |
|---|---:|---|---:|
| bolt | 0.3869 | - | nan |
| bolt-copy | 0.3852 | 0.997 [0.996, 1.015] | 0.68 |
| bolt-pi | 0.4052 | 0.953 [0.944, 0.961] | 0.073 |
| pa-only-alloc | 0.3793 | 1.024 [1.014, 1.033] | 0.00085 |
| pa-only-free | 0.3811 | 1.015 [0.990, 1.038] | 0.49 |
| pa-norb-bolt | 0.3851 | 1.015 [1.002, 1.025] | 0.12 |
| pa-norb-pi | 0.3411 | 1.140 [1.130, 1.157] | 6.1e-05 |
| pa-cache-bolt | 0.3840 | 1.003 [0.993, 1.026] | 0.36 |
| pa-cache-pi | 0.3784 | 1.022 [1.013, 1.060] | 0.00043 |
| pa-lto | 0.3407 | 1.139 [1.133, 1.151] | 6.1e-05 |

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
| bufwrite | 1020 | 984 | -3.53% | 0.01 | 0.01 |
| memo | 812 | 816 | +0.49% | 0.01 | 0.01 |
| trace | 808 | 832 | +2.97% | 0.01 | 0.01 |
| pool | 1000 | 1092 | +9.20% | 0.01 | 0.01 |
| mixed | 884 | 916 | +3.62% | 0.01 | 0.01 |
| memo-lowhit | 812 | 812 | +0.00% | 0.0 | 0.01 |
| unsafe | 1032 | 1032 | +0.00% | 0.01 | 0.01 |
| compute | 1188 | 1228 | +3.37% | 0.01 | 0.01 |
| sqlite | 631968 | 632172 | +0.03% | 0.41 | 0.43 |
| lua | 131136 | 131708 | +0.44% | 0.1 | 0.11 |
| cpython | 1227976 | 1229104 | +0.09% | 1.36 | 1.29 |
| zstd-compress | 65736 | 65896 | +0.24% | 0.08 | 0.09 |
| zstd-decompress | 65736 | 65896 | +0.24% | 0.08 | 0.09 |
| jq | 133408 | 133728 | +0.24% | 0.12 | 0.13 |
| libxml2 | 101288 | 101856 | +0.56% | 0.16 | 0.17 |

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
