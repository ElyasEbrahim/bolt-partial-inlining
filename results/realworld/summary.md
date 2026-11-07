metric: user time (s), rounds: 30; speedup = paired median over rounds of t(bolt)/t(variant)

| workload | variant | median | stdev | speedup vs bolt [95% CI] | p (Wilcoxon) |
|---|---|---:|---:|---|---:|
| sqlite | orig | 0.9813 | 0.0400 | 0.975 [0.960, 0.980] | 0.00023 |
| sqlite | bolt | 0.9497 | 0.0358 | - | - |
| sqlite | bolt-copy | 0.9550 | 0.0273 | 0.997 [0.990, 1.005] | 0.63 |
| sqlite | bolt-pi | 0.9468 | 0.0258 | 0.997 [0.991, 1.007] | 0.87 |
| sqlite | bolt-pi-avg | 0.9513 | 0.0369 | 0.997 [0.990, 1.009] | 0.79 |
| sqlite | bolt-pi-nofe | 0.9467 | 0.0295 | 1.004 [0.988, 1.018] | 0.5 |
| sqlite | bolt-inl | 0.9484 | 0.0503 | 1.003 [0.989, 1.011] | 0.9 |
| sqlite | bolt-inl-pi | 0.9572 | 0.0359 | 0.995 [0.982, 1.010] | 0.75 |
| lua | orig | 1.4043 | 0.0336 | 0.964 [0.960, 0.969] | 2.6e-08 |
| lua | bolt | 1.3569 | 0.0260 | - | - |
| lua | bolt-copy | 1.3516 | 0.0428 | 1.000 [0.993, 1.008] | 0.72 |
| lua | bolt-pi | 1.3597 | 0.0311 | 0.995 [0.988, 1.001] | 0.27 |
| lua | bolt-pi-avg | 1.3637 | 0.0480 | 0.994 [0.986, 1.002] | 0.064 |
| lua | bolt-pi-nofe | 1.3587 | 0.0408 | 0.993 [0.982, 1.000] | 0.055 |
| lua | bolt-inl | 1.3540 | 0.0432 | 1.000 [0.996, 1.003] | 0.44 |
| lua | bolt-inl-pi | 1.3703 | 0.0313 | 0.991 [0.987, 0.998] | 0.0047 |
| cpython | orig | 1.0986 | 0.0119 | 0.940 [0.937, 0.944] | 1.9e-09 |
| cpython | bolt | 1.0351 | 0.0110 | - | - |
| cpython | bolt-copy | 1.0362 | 0.0185 | 0.998 [0.994, 1.001] | 0.3 |
| cpython | bolt-pi | 1.0360 | 0.0096 | 0.997 [0.993, 1.002] | 0.07 |
| cpython | bolt-pi-avg | 1.0368 | 0.0093 | 0.998 [0.996, 0.999] | 0.13 |
| cpython | bolt-pi-nofe | 1.0380 | 0.0130 | 0.999 [0.991, 1.004] | 0.25 |
| cpython | bolt-inl | 1.0436 | 0.0108 | 0.991 [0.987, 0.996] | 0.00031 |
| cpython | bolt-inl-pi | 1.0322 | 0.0101 | 1.003 [0.999, 1.007] | 0.073 |
| zstd-compress | orig | 0.4522 | 0.0130 | 1.001 [0.991, 1.021] | 0.43 |
| zstd-compress | bolt | 0.4546 | 0.0158 | - | - |
| zstd-compress | bolt-copy | 0.4562 | 0.0142 | 1.002 [0.981, 1.010] | 0.69 |
| zstd-compress | bolt-pi | 0.4517 | 0.0132 | 1.003 [0.982, 1.017] | 0.84 |
| zstd-compress | bolt-pi-avg | 0.4492 | 0.0214 | 1.014 [0.981, 1.043] | 0.37 |
| zstd-compress | bolt-pi-nofe | 0.4494 | 0.0149 | 1.018 [0.978, 1.034] | 0.42 |
| zstd-compress | bolt-inl | 0.4522 | 0.0130 | 1.004 [0.983, 1.019] | 0.69 |
| zstd-compress | bolt-inl-pi | 0.4574 | 0.0164 | 1.008 [0.984, 1.024] | 0.87 |
| zstd-decompress | orig | 0.3354 | 0.0266 | 1.009 [0.998, 1.017] | 0.48 |
| zstd-decompress | bolt | 0.3380 | 0.0213 | - | - |
| zstd-decompress | bolt-copy | 0.3375 | 0.0265 | 0.996 [0.986, 1.008] | 0.39 |
| zstd-decompress | bolt-pi | 0.3348 | 0.0251 | 1.008 [0.997, 1.018] | 0.12 |
| zstd-decompress | bolt-pi-avg | 0.3354 | 0.0285 | 1.009 [0.992, 1.016] | 0.89 |
| zstd-decompress | bolt-pi-nofe | 0.3372 | 0.0282 | 1.003 [0.985, 1.012] | 0.57 |
| zstd-decompress | bolt-inl | 0.3384 | 0.0260 | 0.998 [0.993, 1.007] | 0.7 |
| zstd-decompress | bolt-inl-pi | 0.3387 | 0.0322 | 0.994 [0.973, 1.006] | 0.073 |
