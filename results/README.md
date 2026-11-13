# Results

Everything in this directory, except `check-bolt/` and `x86-validation.txt`,
is written by a single run of [`scripts/run_experiments.sh`](../scripts/run_experiments.sh)
in the Docker image built from this repository (`make image experiments`).
`timeline.log` records when each step ran and `environment.txt` the machine,
toolchain and BOLT revisions.

| File | Content |
|---|---|
| [`REPORT.md`](REPORT.md) | all tables: speedups, instruction counts, `pool` analysis, transformation statistics, dyno stats, code size, rejection reasons |
| `speedup.png`, `dynostats.png` | plots of the speedups and of the profile-estimated dynamic effect |
| `report.json` | machine-readable version of the report |
| `micro/`, `realworld/` | `raw.csv` (one row per run: wall, user and system time, max RSS), `summary.json`/`.md` (statistics) and `bench.log` |
| `pool-analysis/` | analysis of the `pool` slowdown (`scripts/pool_analysis.sh`), one directory per experiment: `layout/` (block orders, single callees, LTO, hand-written loops that mirror BOLT outputs), `distance/` (instructions added or removed between the two inlined regions), `placement/` (16 code placements), `counter/` (build without the random number generator in the loop) |
| `icount.json` | executed instructions per variant (valgrind, smaller inputs, every variant run from the same path) |
| `flag-off-identity.txt` | patched `llvm-bolt` without `--partial-inline` vs. upstream `llvm-bolt`, byte by byte |
| `bolt-logs/<workload>/` | `llvm-bolt` logs (incl. `-dyno-stats`, `-v=1`) and processing time of every variant |
| `prepare-*.log`, `icount.log`, `report.log` | logs of the individual steps |
| `check-bolt/` | BOLT lit test results of the upstream and the patched build, as built in the image |
| `x86-validation.txt` | output of `scripts/x86_validate.sh` (x86-64 under emulation) |

Statistics: the timing metric is the user CPU time of the process. Within a
round all variants of a workload run once, in rotated order, each from a fresh
copy of its binary at the same path; `bolt-copy`, a byte-identical copy of
`bolt`, is the A/A control. The speedup of a
variant is the median over rounds of `t(bolt) / t(variant)` (paired), with a
95% bootstrap confidence interval; p-values are from a two-sided Wilcoxon
signed-rank test against `bolt` and are not corrected for multiple
comparisons. `summary.json` also contains unpaired statistics.
