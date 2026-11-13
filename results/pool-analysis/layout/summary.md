metric: user time (s), rounds: 15; speedup = paired median over rounds of t(bolt)/t(variant)

| workload | variant | median | stdev | speedup vs bolt [95% CI] | p (Wilcoxon) |
|---|---|---:|---:|---|---:|
| pool | bolt | 0.3826 | 0.0028 | - | - |
| pool | bolt-copy | 0.3822 | 0.0033 | 1.001 [0.994, 1.002] | 0.85 |
| pool | bolt-pi | 0.4026 | 0.0027 | 0.950 [0.947, 0.956] | 6.1e-05 |
| pool | pa-only-alloc | 0.3748 | 0.0027 | 1.019 [1.014, 1.029] | 6.1e-05 |
| pool | pa-only-free | 0.3726 | 0.0162 | 1.027 [1.016, 1.031] | 0.0084 |
| pool | pa-norb-bolt | 0.3829 | 0.0072 | 0.999 [0.991, 1.008] | 0.42 |
| pool | pa-norb-pi | 0.3368 | 0.0023 | 1.133 [1.126, 1.139] | 6.1e-05 |
| pool | pa-cache-bolt | 0.3846 | 0.0107 | 0.995 [0.984, 0.998] | 0.064 |
| pool | pa-cache-pi | 0.3746 | 0.0097 | 1.021 [1.006, 1.025] | 0.01 |
| pool | pa-lto | 0.3394 | 0.0027 | 1.128 [1.126, 1.132] | 6.1e-05 |
| pool | hw-base | 0.3835 | 0.0033 | 0.999 [0.994, 1.002] | 0.39 |
| pool | hw-straight | 0.4033 | 0.0048 | 0.948 [0.942, 0.950] | 6.1e-05 |
| pool | hw-norb | 0.3372 | 0.0026 | 1.130 [1.125, 1.136] | 6.1e-05 |
| pool | hw-cache | 0.3737 | 0.0035 | 1.023 [1.017, 1.029] | 6.1e-05 |
