metric: user time (s), rounds: 15; speedup = paired median over rounds of t(bolt)/t(variant)

| workload | variant | median | stdev | speedup vs bolt [95% CI] | p (Wilcoxon) |
|---|---|---:|---:|---|---:|
| pool | bolt | 0.3833 | 0.0029 | - | - |
| pool | bolt-copy | 0.3832 | 0.0174 | 1.001 [0.993, 1.002] | 0.98 |
| pool | bolt-pi | 0.4019 | 0.0050 | 0.953 [0.950, 0.960] | 6.1e-05 |
| pool | pa-only-alloc | 0.3746 | 0.0036 | 1.024 [1.019, 1.038] | 6.1e-05 |
| pool | pa-only-free | 0.3719 | 0.0037 | 1.030 [1.028, 1.034] | 6.1e-05 |
| pool | pa-norb-bolt | 0.3826 | 0.0041 | 1.003 [0.993, 1.005] | 0.64 |
| pool | pa-norb-pi | 0.3375 | 0.0037 | 1.133 [1.121, 1.139] | 6.1e-05 |
| pool | pa-cache-bolt | 0.3823 | 0.0017 | 1.002 [1.000, 1.007] | 0.14 |
| pool | pa-cache-pi | 0.3741 | 0.0027 | 1.025 [1.018, 1.027] | 6.1e-05 |
| pool | pa-lto | 0.3380 | 0.0025 | 1.132 [1.130, 1.135] | 6.1e-05 |
| pool | hw-base | 0.3838 | 0.0029 | 0.999 [0.992, 1.002] | 0.45 |
| pool | hw-straight | 0.4005 | 0.0043 | 0.956 [0.948, 0.960] | 6.1e-05 |
| pool | hw-norb | 0.3374 | 0.0032 | 1.135 [1.129, 1.141] | 6.1e-05 |
| pool | hw-cache | 0.3749 | 0.0034 | 1.019 [1.009, 1.022] | 6.1e-05 |
