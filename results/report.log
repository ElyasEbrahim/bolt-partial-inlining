# Evaluation report

Metric: user CPU time of the whole process. All variants of a workload run once per round in rotated order; speedup = median over rounds of t(bolt)/t(variant) (paired), with a 95% bootstrap confidence interval; p = two-sided Wilcoxon signed-rank test of `bolt-pi` against `bolt`. Every run's output was verified against the original binary.

## Speedup over the BOLT baseline

`bolt-copy` is a byte-identical copy of `bolt` (A/A control): it shows the size of differences the measurement reports when there is none.

| workload | class | rounds | bolt [s] | bolt-copy | bolt-pi | bolt-pi-avg | bolt-pi-nofe | bolt-inl | bolt-inl-pi | p (bolt-pi) |
|---|---|---:|---:|---|---|---|---|---|---|---:|
| bufwrite | target | 15 | 0.936 | 1.000 [0.998, 1.002] | 1.003 [1.001, 1.004] | 1.002 [1.001, 1.005] | 0.999 [0.995, 1.001] | 0.999 [0.994, 1.001] | 1.002 [1.001, 1.005] | 0.45 |
| memo | target | 15 | 0.761 | 0.998 [0.995, 1.000] | 1.018 [1.008, 1.020] | 1.017 [1.010, 1.019] | 0.998 [0.987, 1.000] | 0.993 [0.989, 0.995] | 1.018 [1.018, 1.020] | 0.0084 |
| trace | target | 15 | 0.402 | 1.002 [1.001, 1.004] | 1.671 [1.666, 1.674] | 1.669 [1.665, 1.675] | 1.665 [1.661, 1.668] | 1.002 [0.998, 1.005] | 1.667 [1.664, 1.668] | 6.1e-05 |
| pool | target | 15 | 0.374 | 0.998 [0.995, 1.001] | 0.959 [0.955, 0.960] | 0.957 [0.955, 0.961] | 1.026 [1.023, 1.029] | 1.026 [1.023, 1.027] | 0.957 [0.957, 0.961] | 6.1e-05 |
| lookup | target | 15 | 0.468 | 1.000 [0.999, 1.001] | 1.450 [1.442, 1.454] | 1.451 [1.448, 1.456] | 1.451 [1.444, 1.454] | 1.598 [1.593, 1.604] | 1.594 [1.591, 1.606] | 6.1e-05 |
| chain | target | 15 | 0.575 | 1.001 [1.000, 1.003] | 2.565 [2.561, 2.571] | 2.568 [2.558, 2.570] | 2.563 [2.551, 2.567] | 2.577 [2.570, 2.581] | 2.580 [2.570, 2.583] | 6.1e-05 |
| mixed | adversarial | 15 | 0.352 | 1.000 [0.996, 1.004] | 2.722 [2.707, 2.728] | 2.428 [2.410, 2.434] | 2.720 [2.715, 2.724] | 1.149 [1.144, 1.152] | 2.717 [2.695, 2.731] | 6.1e-05 |
| memo-lowhit | neutral | 15 | 3.032 | 0.997 [0.989, 1.003] | 0.999 [0.994, 1.005] | 1.000 [0.992, 1.003] | 0.999 [0.994, 1.008] | 1.002 [0.999, 1.008] | 1.001 [0.999, 1.005] | 0.98 |
| lookup-deep | neutral | 15 | 0.332 | 0.998 [0.976, 1.009] | 1.002 [0.988, 1.010] | 0.998 [0.981, 1.016] | 0.998 [0.991, 1.005] | 1.514 [1.499, 1.536] | 1.518 [1.506, 1.534] | 0.89 |
| unsafe | neutral | 15 | 0.330 | 1.004 [0.992, 1.014] | 0.998 [0.992, 1.011] | 1.000 [0.995, 1.008] | 0.996 [0.980, 1.008] | 0.996 [0.986, 1.007] | 0.996 [0.986, 1.009] | 0.8 |
| compute | neutral | 15 | 0.311 | 1.002 [0.992, 1.012] | 1.000 [0.991, 1.012] | 1.002 [0.994, 1.006] | 1.001 [0.995, 1.006] | 0.999 [0.988, 1.009] | 0.994 [0.989, 0.999] | 1 |
| sqlite | real | 30 | 0.952 | 1.000 [0.992, 1.016] | 1.005 [0.988, 1.012] | 1.007 [0.997, 1.014] | 1.005 [0.990, 1.019] | 1.001 [0.989, 1.013] | 0.999 [0.984, 1.007] | 0.89 |
| lua | real | 30 | 1.426 | 1.005 [0.992, 1.013] | 1.004 [0.993, 1.013] | 1.011 [0.991, 1.023] | 0.994 [0.987, 1.010] | 1.001 [0.992, 1.012] | 1.011 [1.002, 1.021] | 0.61 |
| cpython | real | 30 | 1.048 | 1.000 [0.993, 1.005] | 1.009 [0.997, 1.012] | 1.003 [0.999, 1.014] | 1.006 [0.994, 1.011] | 1.002 [0.994, 1.006] | 1.003 [1.000, 1.008] | 0.16 |
| zstd-compress | real | 30 | 0.455 | 1.008 [0.984, 1.023] | 1.004 [0.992, 1.020] | 1.007 [0.984, 1.035] | 1.002 [0.994, 1.021] | 1.014 [0.996, 1.025] | 1.000 [0.985, 1.026] | 0.58 |
| zstd-decompress | real | 30 | 0.338 | 0.994 [0.979, 1.009] | 1.013 [0.984, 1.034] | 1.009 [0.987, 1.016] | 0.996 [0.987, 1.015] | 1.004 [0.983, 1.018] | 1.001 [0.995, 1.023] | 0.38 |
| jq | real | 30 | 1.195 | 0.999 [0.993, 1.005] | 1.069 [1.060, 1.079] | 1.076 [1.068, 1.087] | 1.065 [1.045, 1.072] | 1.101 [1.092, 1.114] | 1.110 [1.097, 1.119] | 3.7e-09 |
| libxml2 | real | 30 | 0.553 | 1.004 [0.994, 1.010] | 1.014 [1.005, 1.031] | 1.009 [1.001, 1.017] | 1.009 [1.000, 1.015] | 1.012 [0.990, 1.022] | 1.011 [1.001, 1.027] | 0.0047 |

## Partial inlining without trivial callees

`bolt-pi-skip` is `bolt-pi` with the named callees excluded (`-partial-inline-skip`): trivial functions that BOLT's existing `-inline-all` inlines as well. The difference to `bolt` is the share that only partial inlining achieves.

| workload | excluded | bolt-pi | bolt-pi-skip | bolt-inl | bolt-inl-pi | calls avoided bolt-pi | calls avoided bolt-pi-skip | p (bolt-pi-skip) |
|---|---|---|---|---|---|---:|---:|---:|
| jq | `jv_get_kind` | 1.069 [1.060, 1.079] | 1.016 [1.006, 1.031] | 1.101 [1.092, 1.114] | 1.110 [1.097, 1.119] | 26.40% | 8.67% | 0.0012 |

## Effect of the extensions

`bolt-pi-noext` is `bolt-pi` without fast paths through the first iteration of a loop and without saved registers (`-partial-inline-loops=false -partial-inline-save-regs=false`): the pass as in version 1.2.0. For the workloads that are not listed, both binaries are byte-identical: bufwrite, memo, trace, pool, mixed, memo-lowhit, lookup-deep, unsafe, compute, zstd-compress, zstd-decompress, jq, libxml2.

| workload | bolt-pi-noext | bolt-pi | calls avoided noext | calls avoided bolt-pi | sites through a loop | sites with saved registers | instructions noext | instructions bolt-pi |
|---|---|---|---:|---:|---:|---:|---:|---:|
| lookup | 1.001 [0.997, 1.002] | 1.450 [1.442, 1.454] | 0.00% | 94.64% | 1 | 0 | +0.00% | -6.96% |
| chain | 0.999 [0.997, 1.002] | 2.565 [2.561, 2.571] | 0.00% | 98.44% | 0 | 1 | +0.00% | -7.90% |
| sqlite | 1.006 [0.995, 1.019] | 1.005 [0.988, 1.012] | 4.07% | 4.20% | 0 | 1 | -0.06% | -0.06% |
| lua | 1.010 [0.996, 1.015] | 1.004 [0.993, 1.013] | 12.66% | 15.45% | 1 | 3 | -0.41% | -0.53% |
| cpython | 1.009 [0.997, 1.013] | 1.009 [0.997, 1.012] | 4.54% | 4.69% | 1 | 2 | -0.27% | -0.28% |

## Executed instructions (valgrind, smaller inputs; change vs. bolt)

All instructions of the process; every variant is executed from the same path (see scripts/icount.py).

| workload | bolt [instructions] | orig | bolt-pi | bolt-pi-nofe | bolt-inl | bolt-inl-pi |
|---|---:|---:|---:|---:|---:|---:|
| bufwrite | 138,318,069 | +2.17% | -23.85% | +0.00% | -0.00% | -23.85% |
| memo | 81,011,309 | +2.34% | -16.28% | +0.00% | -0.13% | -16.40% |
| trace | 75,098,604 | -0.00% | -15.98% | -15.98% | -0.00% | -15.98% |
| pool | 88,102,221 | +2.27% | -24.97% | -4.54% | -4.54% | -24.97% |
| lookup | 43,134,381 | -0.00% | -6.96% | -6.96% | -9.24% | -9.24% |
| chain | 22,536,894 | -0.00% | -7.90% | -7.90% | -17.61% | -17.61% |
| mixed | 46,300,637 | +1.30% | -12.96% | -12.96% | -5.18% | -20.73% |
| memo-lowhit | 180,335,983 | -0.00% | +0.00% | +0.00% | -0.54% | -0.54% |
| lookup-deep | 17,014,537 | -0.00% | +0.00% | +0.00% | -9.21% | -9.21% |
| unsafe | 26,129,237 | -0.00% | +0.00% | +0.00% | -0.02% | -0.02% |
| compute | 79,632,300 | -0.00% | -0.00% | -0.00% | +0.00% | +0.00% |
| sqlite | 1,175,824,476 | +0.83% | -0.06% | -0.03% | -0.07% | -0.10% |
| lua | 3,127,950,744 | +1.37% | -0.53% | -0.15% | -0.26% | -0.73% |
| cpython | 2,630,679,571 | +0.33% | -0.28% | -0.06% | -0.10% | -0.45% |
| zstd-compress | 945,884,181 | -0.00% | +0.00% | +0.00% | -0.00% | -0.00% |
| zstd-decompress | 331,355,307 | -0.12% | -0.00% | -0.00% | -0.00% | -0.00% |
| jq | 1,681,099,979 | +0.72% | -1.97% | -1.26% | -2.07% | -2.86% |
| libxml2 | 485,579,990 | +1.13% | -1.51% | -0.14% | -0.28% | -1.67% |

## pool: analysis of the slowdown (15 rounds per table)

`hw-*` are hand-written variants of the loop (`scripts/pool_loop.py`); speedups are relative to `bolt` of the same table.

### Block orders, single callees, LTO; hand-written loops that mirror BOLT outputs

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3833 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3832 | 1.001 [0.993, 1.002] | 0.98 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4019 | 0.953 [0.950, 0.960] | 6.1e-05 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.3746 | 1.024 [1.019, 1.038] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3719 | 1.030 [1.028, 1.034] | 6.1e-05 |
| pa-norb-bolt | baseline, original block order | 0.3826 | 1.003 [0.993, 1.005] | 0.64 |
| pa-norb-pi | partial inlining, original block order | 0.3375 | 1.133 [1.121, 1.139] | 6.1e-05 |
| pa-cache-bolt | baseline, `-reorder-blocks=cache` | 0.3823 | 1.002 [1.000, 1.007] | 0.14 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3741 | 1.025 [1.018, 1.027] | 6.1e-05 |
| pa-lto | compiler LTO (inlines both functions) | 0.3380 | 1.132 [1.130, 1.135] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3838 | 0.999 [0.992, 1.002] | 0.45 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4005 | 0.956 [0.948, 0.960] | 6.1e-05 |
| hw-norb | hand-written loop of `pa-norb-pi` | 0.3374 | 1.135 [1.129, 1.141] | 6.1e-05 |
| hw-cache | hand-written loop of `pa-cache-pi` | 0.3749 | 1.019 [1.009, 1.022] | 6.1e-05 |

### Instructions between the two inlined regions

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| bolt |  | 0.3822 | - | - |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3838 | 0.999 [0.992, 1.007] | 0.72 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.3825 | 0.998 [0.988, 1.013] | 0.85 |
| hw-short2 | `hw-straight`, 2 instructions fewer between the regions | 0.4662 | 0.817 [0.813, 0.825] | 6.1e-05 |
| hw-short1 | `hw-straight`, 1 instruction fewer (no register copy) | 0.4490 | 0.851 [0.846, 0.857] | 6.1e-05 |
| hw-samebase | `hw-straight`, same base register in both regions | 0.4080 | 0.935 [0.932, 0.941] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4063 | 0.953 [0.929, 0.954] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3789 | 1.006 [0.998, 1.008] | 0.064 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3595 | 1.061 [1.051, 1.069] | 6.1e-05 |
| hw-gap+3 | `hw-straight`, 3 nops between the regions | 0.3645 | 1.049 [1.035, 1.099] | 6.1e-05 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.3533 | 1.077 [1.067, 1.099] | 6.1e-05 |
| hw-gap+5 | `hw-straight`, 5 nops between the regions | 0.4655 | 0.822 [0.815, 0.830] | 6.1e-05 |
| hw-gap+6 | `hw-straight`, 6 nops between the regions | 0.3566 | 1.069 [1.067, 1.082] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3520 | 1.085 [1.083, 1.099] | 6.1e-05 |
| hw-gap+16 | `hw-straight`, 16 nops between the regions | 0.3534 | 1.083 [1.079, 1.090] | 6.1e-05 |
| hw-tail+4 | `hw-straight`, 4 nops after the second region | 0.3628 | 1.053 [1.052, 1.068] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.3832 | 1.013 [0.902, 1.048] | 0.52 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3568 | 1.070 [1.050, 1.113] | 0.01 |

### Code placement

Each loop shifted by 0, 4, ..., 60 bytes (nops in front of the loop that are not executed); speedup vs bolt per placement.

| loop | min | median | max | all 16 placements |
|---|---:|---:|---:|---|
| hw-base | 0.995 | 1.009 | 1.024 | 0.998 1.023 0.998 1.021 0.995 1.023 0.998 1.024 0.995 1.017 1.001 1.019 0.995 1.024 0.995 1.022 |
| hw-straight | 0.937 | 0.955 | 0.963 | 0.948 0.948 0.955 0.955 0.958 0.950 0.954 0.953 0.961 0.963 0.963 0.957 0.957 0.937 0.955 0.951 |

### Build with `slot = i & (w - 1)` (no random number generator in the loop)

| variant | | median [s] | speedup vs bolt [95% CI] | p |
|---|---|---:|---|---:|
| orig | compiler output | 0.3475 | 0.995 [0.994, 0.999] | 0.041 |
| bolt |  | 0.3453 | - | - |
| bolt-copy | identical copy of bolt (control) | 0.3443 | 1.002 [0.995, 1.007] | 0.52 |
| bolt-pi | partial inlining, ext-tsp block order (default) | 0.4308 | 0.803 [0.799, 0.805] | 6.1e-05 |
| pa-only-alloc | only `pool_alloc` partially inlined | 0.3952 | 0.871 [0.868, 0.897] | 6.1e-05 |
| pa-only-free | only `pool_free` partially inlined | 0.3453 | 1.003 [0.998, 1.007] | 0.72 |
| pa-norb-pi | partial inlining, original block order | 0.3274 | 1.052 [1.049, 1.061] | 6.1e-05 |
| pa-cache-pi | partial inlining, `-reorder-blocks=cache` | 0.3755 | 0.914 [0.912, 0.926] | 6.1e-05 |
| pa-lto | compiler LTO (inlines both functions) | 0.1086 | 3.153 [3.113, 3.213] | 6.1e-05 |
| hw-base | hand-written loop of `bolt` (two calls) | 0.3464 | 0.998 [0.990, 1.012] | 0.8 |
| hw-base-head+1 | `hw-base` with one nop in the loop head | 0.4359 | 0.791 [0.785, 0.796] | 6.1e-05 |
| hw-straight | hand-written loop of `bolt-pi` | 0.4234 | 0.810 [0.804, 0.817] | 6.1e-05 |
| hw-gap+1 | `hw-straight`, 1 nop between the regions | 0.3908 | 0.884 [0.869, 0.890] | 6.1e-05 |
| hw-gap+2 | `hw-straight`, 2 nops between the regions | 0.3179 | 1.087 [1.055, 1.151] | 0.00031 |
| hw-gap+4 | `hw-straight`, 4 nops between the regions | 0.2555 | 1.342 [1.329, 1.357] | 6.1e-05 |
| hw-gap+8 | `hw-straight`, 8 nops between the regions | 0.3766 | 0.920 [0.905, 0.954] | 6.1e-05 |
| hw-fwd1 | `hw-straight`, reload of `p->live` replaced by a register copy | 0.2990 | 1.151 [1.044, 1.177] | 0.083 |
| hw-fwd3 | `hw-straight`, all three reloads replaced by register copies | 0.3570 | 0.966 [0.850, 1.059] | 0.28 |

## Coverage on the real programs and what limits it

From the training profiles and `llvm-bolt -v=2`, without timing (`scripts/coverage.py`). *Entries*: transfers to the entry of another function in the instrumentation profile. *Unattributed*: entries whose caller the profile does not know, i.e. calls from functions that BOLT cannot rewrite and from outside the binary.

| program | entries | unattributed | direct calls at call sites the pass can transform | avoided | hottest callees of unattributed calls |
|---|---:|---:|---:|---:|---|
| sqlite | 44.85M | 23.4% | 23.82M | 1.00M (4.2%) | `sqlite3BtreeNext/1` 1.87M, `btreeParseCellPtr/1` 1.70M, `applyAffinity/1` 0.66M |
| lua | 104.18M | 42.2% | 54.61M | 8.44M (15.4%) | `luaH_getshortstr/1` 25.96M, `luaH_psetshortstr/1` 7.20M, `luaD_precall/1` 3.38M |
| cpython | 98.03M | 30.9% | 54.94M | 2.58M (4.7%) | `_PyFloat_FromDouble_ConsumeInputs/1` 7.20M, `_Py_Dealloc` 3.55M, `_PyObject_Free/1` 2.09M |
| zstd | 0.07M | 0.1% | 0.07M | 0.00M (1.2%) | `AIO_ReadPool_executeReadJob/1` 0.00M, `UTIL_freeFileNamesTable` 0.00M, `ZSTD_minCLevel` 0.00M |
| jq | 293.68M | 32.9% | 197.56M | 52.16M (26.4%) | `jv_get_kind` 36.94M, `stack_push` 26.28M, `jv_copy` 12.18M |
| libxml2 | 28.51M | 15.6% | 18.92M | 4.87M (25.7%) | `xmlXPathNextChildElement/1` 1.20M, `xmlXPathNodeSetAddUnique` 1.02M, `xmlXPathNextDescendantOrSelf` 0.90M |

### Callees of hot call sites without a usable fast region

Executions of the rejected callees as a share of the direct calls in the previous table, by reason, with the hottest callee. The shares are upper bounds: the execution count of a callee also contains indirect and unattributed calls.

| program | not-simple | no-fast-exit | entry-not-copyable | side-effect | cold-fast-path | too-large | stack-access | frame-mismatch |
|---|---|---|---|---|---|---|---|---|
| sqlite | 48.9% (`memcpy@PLT`) | 22.6% (`patternCompare`) | 3.5% (`computeCellSize`) | 12.4% (`sqlite3BtreeNext`) | 3.9% (`sqlite3VdbeMemSetText`) | 6.8% (`sqlite3VdbeRecordCompareWithSkip`) | 0.9% (`freeSpace`) | 0.6% (`releaseMemArray`) |
| lua | 16.6% (`realloc@PLT`) | 20.9% (`match`) | 15.7% (`luaM_free_`) | 6.6% (`luaD_precall`) | 7.5% (`singlematch`) | 18.5% (`luaH_psetshortstr`) | 1.5% (`lua_tonumberx`) | - |
| cpython | 35.8% (`_Py_NewReference`) | 41.1% (`_Py_Dealloc`) | 10.6% (`PyObject_Free`) | 3.4% (`_PyFrame_ClearExceptCode`) | 8.8% (`PyLong_FromLong`) | 2.5% (`unicodekeys_lookup_unicode`) | 1.6% (`_Py_dict_lookup`) | 0.1% (`maybe_small_long`) |
| zstd | 91.6% (`memmove@PLT`) | 5.4% (`FSE_readNCount_bmi2`) | 0.7% (`FSE_readNCount`) | 1.0% (`FSE_initDState`) | 0.0% (`AIO_ReadPool_fillBuffer`) | - | - | - |
| jq | 20.1% (`free@PLT`) | 20.3% (`jv_free`) | 19.9% (`jv_mem_free`) | - | - | 0.4% (`jvp_number_cmp`) | - | - |
| libxml2 | 8.8% (`memcpy@PLT`) | 45.8% (`xmlParserShrink`) | 3.5% (`xmlDictLookupHashed`) | 1.6% (`nodePop`) | - | 1.3% (`xmlIsID`) | - | 1.6% (`xmlNextChar`) |

### Region size limits and extensions

Calls avoided (share of the direct calls), BOLT's estimate of the executed instructions and code size, each relative to `bolt`, for `-partial-inline-max-insns` / `-max-blocks`. 24/8 is the default; *without extensions* is 24/8 with `-partial-inline-loops=false -partial-inline-save-regs=false`.

| program | without extensions | 16/6 | 24/8 | 32/8 | 40/12 | 64/16 |
|---|---|---|---|---|---|---|
| sqlite | 4.1%, -0.14%, +0.03% | 1.4%, -0.05%, -0.03% | 4.2%, -0.16%, +0.04% | 4.2%, -0.16%, +0.04% | 5.8%, -0.41%, +0.12% | 5.5%, -0.38%, +0.13% |
| lua | 12.7%, -1.02%, +0.44% | 10.0%, -0.68%, +0.34% | 15.4%, -1.27%, +0.68% | 16.4%, -1.25%, +0.78% | 18.6%, -1.51%, +1.31% | 18.6%, -1.51%, +1.31% |
| cpython | 4.5%, -0.62%, +0.10% | 4.2%, -0.61%, +0.08% | 4.7%, -0.63%, +0.11% | 4.7%, -0.63%, +0.11% | 4.7%, -0.63%, +0.11% | 4.7%, -0.64%, +0.14% |
| zstd | 1.2%, -0.00%, +0.24% | 1.2%, -0.00%, +0.24% | 1.2%, -0.00%, +0.24% | 1.2%, -0.00%, +0.24% | 1.2%, -0.00%, +0.24% | 1.2%, -0.00%, +0.24% |
| jq | 26.4%, -2.97%, +0.24% | 26.4%, -2.97%, +0.24% | 26.4%, -2.97%, +0.24% | 26.4%, -2.97%, +0.24% | 26.4%, -2.97%, +0.24% | 26.8%, -3.12%, +0.43% |
| libxml2 | 25.7%, -2.39%, +0.56% | 3.8%, -0.48%, +0.10% | 25.7%, -2.39%, +0.56% | 25.7%, -2.39%, +0.56% | 30.5%, -2.70%, +0.75% | 30.5%, -2.70%, +0.75% |

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
| cpython | 18 | 17 | 7 | 2 | 1 | 2 | 200 | 3 | 2576849 (4.69%) |
| zstd-compress | 5 | 5 | 0 | 0 | 0 | 0 | 29 | 0 | 819 (1.24%) |
| zstd-decompress | 5 | 5 | 0 | 0 | 0 | 0 | 29 | 0 | 819 (1.24%) |
| jq | 9 | 21 | 5 | 1 | 0 | 0 | 99 | 4 | 52156991 (26.40%) |
| libxml2 | 8 | 7 | 5 | 0 | 0 | 0 | 95 | 0 | 4866953 (25.72%) |

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
| zstd-compress | -0.00% | -0.65% | +0.00% | +0.00% | +0.00% |
| zstd-decompress | -0.00% | -0.65% | +0.00% | +0.00% | +0.00% |
| jq | -2.97% | -21.81% | +1.71% | -1.29% | -1.62% |
| libxml2 | -2.39% | -18.61% | +0.01% | -2.59% | -5.53% |

## Code size and BOLT processing time

| workload | .text bolt [B] | .text bolt-pi [B] | growth | llvm-bolt time bolt [s] | bolt-pi [s] |
|---|---:|---:|---:|---:|---:|
| bufwrite | 1020 | 984 | -3.53% | 0.01 | 0.01 |
| memo | 812 | 816 | +0.49% | 0.0 | 0.01 |
| trace | 808 | 832 | +2.97% | 0.0 | 0.01 |
| pool | 1000 | 1092 | +9.20% | 0.0 | 0.01 |
| lookup | 888 | 952 | +7.21% | 0.0 | 0.01 |
| chain | 668 | 732 | +9.58% | 0.0 | 0.01 |
| mixed | 884 | 916 | +3.62% | 0.0 | 0.01 |
| memo-lowhit | 812 | 812 | +0.00% | 0.0 | 0.01 |
| lookup-deep | 876 | 876 | +0.00% | 0.0 | 0.01 |
| unsafe | 920 | 920 | +0.00% | 0.01 | 0.01 |
| compute | 1188 | 1228 | +3.37% | 0.0 | 0.01 |
| sqlite | 631968 | 632208 | +0.04% | 0.37 | 0.4 |
| lua | 131136 | 132028 | +0.68% | 0.09 | 0.1 |
| cpython | 1226288 | 1227632 | +0.11% | 1.1 | 1.15 |
| zstd-compress | 65736 | 65896 | +0.24% | 0.08 | 0.08 |
| zstd-decompress | 65736 | 65896 | +0.24% | 0.08 | 0.08 |
| jq | 133408 | 133728 | +0.24% | 0.12 | 0.13 |
| libxml2 | 101288 | 101856 | +0.56% | 0.15 | 0.15 |

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
| cpython | 16 | 0 | 11 | 38 | 1 | 1 | 9 | 0 | 0 | 4 | 7 |
| zstd-compress | 5 | 0 | 1 | 18 | 0 | 0 | 4 | 0 | 0 | 0 | 1 |
| zstd-decompress | 5 | 0 | 1 | 18 | 0 | 0 | 4 | 0 | 0 | 0 | 1 |
| jq | 5 | 0 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| libxml2 | 5 | 0 | 3 | 25 | 0 | 2 | 1 | 0 | 0 | 1 | 0 |
