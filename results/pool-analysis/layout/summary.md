metric: user time (s), rounds: 15; speedup = paired median over rounds of t(bolt)/t(variant)

| workload | variant | median | stdev | speedup vs bolt [95% CI] | p (Wilcoxon) |
|---|---|---:|---:|---|---:|
| pool | bolt | 0.3820 | 0.0085 | - | - |
| pool | bolt-copy | 0.3822 | 0.0131 | 1.000 [0.997, 1.002] | 0.98 |
| pool | bolt-pi | 0.4027 | 0.0014 | 0.949 [0.947, 0.954] | 0.00012 |
| pool | pa-only-alloc | 0.3749 | 0.0011 | 1.021 [1.015, 1.023] | 6.1e-05 |
| pool | pa-only-free | 0.3717 | 0.0018 | 1.025 [1.023, 1.033] | 6.1e-05 |
| pool | pa-norb-bolt | 0.3822 | 0.0023 | 0.998 [0.995, 1.003] | 0.72 |
| pool | pa-norb-pi | 0.3364 | 0.0009 | 1.137 [1.134, 1.139] | 6.1e-05 |
| pool | pa-cache-bolt | 0.3827 | 0.0124 | 0.999 [0.995, 1.002] | 0.19 |
| pool | pa-cache-pi | 0.3741 | 0.0014 | 1.022 [1.018, 1.025] | 6.1e-05 |
| pool | pa-lto | 0.3369 | 0.0009 | 1.134 [1.133, 1.135] | 6.1e-05 |
| pool | hw-base | 0.3832 | 0.0250 | 0.996 [0.994, 1.000] | 0.041 |
| pool | hw-straight | 0.4000 | 0.0040 | 0.956 [0.951, 0.960] | 0.00031 |
| pool | hw-norb | 0.3370 | 0.0013 | 1.134 [1.130, 1.138] | 6.1e-05 |
| pool | hw-cache | 0.3747 | 0.0018 | 1.019 [1.015, 1.027] | 6.1e-05 |
