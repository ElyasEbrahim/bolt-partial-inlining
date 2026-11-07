#!/usr/bin/env python3
"""Interleaved, repeated timing of BOLT variants with output verification.

For every workload and round, all variants are run back to back in a rotated
order (round r starts with variant r mod N) so that slow drifts of the host
(thermal state, background load) affect all variants equally. Each run records
wall-clock time and user/system CPU time (from wait4). The standard output of
every run (exit code and SHA-256 of stdout) is compared with the output of
the original binary 'orig'.

With --stage-dir, every single run first copies the variant's binary to a new
file <stage-dir>/prog and executes that copy. All variants then run under the
same path (argv[0], and with it the initial stack layout, is identical), and
every run gets freshly allocated page-cache pages for the binary. Without
this, each variant keeps its path and its physical pages for the whole
session, a fixed per-file condition that pairing over rounds cannot remove:
two byte-identical binaries differed by 1.5% (p = 0.003) in such a run. The
variant 'bolt-copy', a byte-identical copy of 'bolt', measures how large a
difference the method reports when there is none.

Results: <out>/raw.csv (one row per run) and <out>/summary.json/.md with the
median, mean, standard deviation and 95% confidence interval of every variant,
and its speedup over the 'bolt' baseline:
  * unpaired: ratio of medians, bootstrap CI, Mann-Whitney U test;
  * paired (primary): median over rounds of t(bolt, r) / t(variant, r), which
    cancels slow changes of the host state between rounds, with a bootstrap
    CI over rounds and a Wilcoxon signed-rank test.
--summarize recomputes the summary from an existing raw.csv.
"""
import argparse
import csv
import hashlib
import json
import os
import random
import shutil
import statistics
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from workloads import FILTERS, WORKLOADS, expand  # noqa: E402


def run_once(cmd, cwd, env):
    start = time.perf_counter_ns()
    proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL)
    out = proc.stdout.read()
    _, status, ru = os.wait4(proc.pid, 0)
    wall = (time.perf_counter_ns() - start) / 1e9
    proc.stdout.close()
    code = os.waitstatus_to_exitcode(status)
    return wall, ru.ru_utime, ru.ru_stime, ru.ru_maxrss, code, out


def stage(binary, stage_dir):
    """Copy binary to a new file <stage_dir>/prog (fresh inode and pages)."""
    dst = os.path.join(stage_dir, "prog")
    if os.path.exists(dst):
        os.unlink(dst)
    shutil.copyfile(binary, dst)
    os.chmod(dst, 0o755)
    return dst


def bootstrap_ratio_ci(base, new, iters=4000, seed=1):
    rnd = random.Random(seed)
    ratios = []
    for _ in range(iters):
        b = statistics.median(rnd.choices(base, k=len(base)))
        n = statistics.median(rnd.choices(new, k=len(new)))
        ratios.append(b / n)
    ratios.sort()
    return ratios[int(0.025 * iters)], ratios[int(0.975 * iters)]


def paired_ratio_ci(base, new, iters=4000, seed=1):
    ratios = [b / n for b, n in zip(base, new)]
    rnd = random.Random(seed)
    boot = sorted(statistics.median(rnd.choices(ratios, k=len(ratios)))
                  for _ in range(iters))
    return (statistics.median(ratios),
            (boot[int(0.025 * iters)], boot[int(0.975 * iters)]))


def wilcoxon_p(a, b):
    try:
        from scipy.stats import wilcoxon
        return float(wilcoxon(a, b).pvalue)
    except Exception:
        return float("nan")


def mann_whitney_p(a, b):
    try:
        from scipy.stats import mannwhitneyu
        return float(mannwhitneyu(a, b, alternative="two-sided").pvalue)
    except Exception:  # scipy missing
        return float("nan")


def t_ci(values):
    if len(values) < 2:
        return (values[0], values[0])
    m = statistics.mean(values)
    s = statistics.stdev(values)
    try:
        from scipy.stats import t
        q = t.ppf(0.975, len(values) - 1)
    except Exception:
        q = 1.96
    h = q * s / len(values) ** 0.5
    return (m - h, m + h)


def summarize(samples, metric):
    """Statistics for {variant: {metric: [value per round]}}."""
    res = {"variants": {}}
    base = samples.get("bolt", {}).get(metric)
    for v, ms in samples.items():
        vals = ms[metric]
        st = {
            "n": len(vals),
            "median": statistics.median(vals),
            "mean": statistics.mean(vals),
            "stdev": statistics.stdev(vals) if len(vals) > 1 else 0.0,
            "ci95_mean": t_ci(vals),
            "median_wall": statistics.median(ms["wall"]),
        }
        if base and v != "bolt":
            st["speedup_vs_bolt_unpaired"] = statistics.median(base) / st["median"]
            st["speedup_ci95_unpaired"] = bootstrap_ratio_ci(base, vals)
            st["mannwhitney_p"] = mann_whitney_p(base, vals)
            st["speedup_vs_bolt"], st["speedup_ci95"] = paired_ratio_ci(base, vals)
            st["wilcoxon_p"] = wilcoxon_p(base, vals)
        if "orig" in samples and v != "orig":
            st["speedup_vs_orig"], st["speedup_vs_orig_ci95"] = paired_ratio_ci(
                samples["orig"][metric], vals)
        res["variants"][v] = st
    return res


def load_raw(path):
    """Samples per workload from raw.csv, ordered by round."""
    rows = list(csv.DictReader(open(path)))
    out = {}
    for r in sorted(rows, key=lambda r: int(r["round"])):
        ms = out.setdefault(r["workload"], {}).setdefault(
            r["variant"], {"wall": [], "user": [], "cpu": []})
        ms["wall"].append(float(r["wall_s"]))
        ms["user"].append(float(r["user_s"]))
        ms["cpu"].append(float(r["user_s"]) + float(r["sys_s"]))
    return out


def write_summary(outdir, summary, metric, rounds):
    sp = os.path.join(outdir, "summary.json")
    json.dump(summary, open(sp, "w"), indent=2)
    old = summary
    with open(os.path.join(outdir, "summary.md"), "w") as f:
        f.write(f"metric: {metric} time (s), rounds: {rounds}; speedup = paired "
                "median over rounds of t(bolt)/t(variant)\n\n")
        f.write("| workload | variant | median | stdev | speedup vs bolt [95% CI] "
                "| p (Wilcoxon) |\n|---|---|---:|---:|---|---:|\n")
        for name, res in old.items():
            for v, st in res["variants"].items():
                sp_ = st.get("speedup_vs_bolt")
                ci = st.get("speedup_ci95")
                spstr = f"{sp_:.3f} [{ci[0]:.3f}, {ci[1]:.3f}]" if sp_ else "-"
                p = st.get("wilcoxon_p")
                pstr = "-" if p is None else f"{p:.2g}"
                f.write(f"| {name} | {v} | {st['median']:.4f} | {st['stdev']:.4f} | "
                        f"{spstr} | {pstr} |\n")
    print(open(os.path.join(outdir, "summary.md")).read())


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", default="/work/out",
                    help="directory containing <workload>/<variant>")
    ap.add_argument("--out", required=True, help="result directory")
    ap.add_argument("--only", nargs="*", help="subset of workloads")
    ap.add_argument("--variants",
                    default="orig,bolt,bolt-copy,bolt-pi,bolt-pi-avg,bolt-pi-nofe,"
                            "bolt-inl,bolt-inl-pi")
    ap.add_argument("--rounds", type=int, default=15)
    ap.add_argument("--warmup", type=int, default=1)
    ap.add_argument("--stage-dir",
                    help="run every variant from a fresh copy in this directory "
                         "(preferably a tmpfs mounted with exec)")
    ap.add_argument("--metric", default="user", choices=["wall", "user", "cpu"],
                    help="metric used for the summary statistics")
    ap.add_argument("--summarize", action="store_true",
                    help="only recompute the summary from <out>/raw.csv")
    args = ap.parse_args()
    if args.summarize:
        data = load_raw(os.path.join(args.out, "raw.csv"))
        summary = {w: summarize(s, args.metric) for w, s in data.items()}
        write_summary(args.out, summary, args.metric,
                      max(len(v["user"]) for s in data.values() for v in s.values()))
        return

    variants = args.variants.split(",")
    names = args.only or list(WORKLOADS)
    os.makedirs(args.out, exist_ok=True)
    # Each invocation writes a complete, self-contained result set.
    raw = open(os.path.join(args.out, "raw.csv"), "w", newline="")
    writer = csv.writer(raw)
    writer.writerow(["workload", "variant", "round", "wall_s", "user_s",
                     "sys_s", "maxrss_kb"])
    summary = {}
    for name in names:
        wl = WORKLOADS[name]
        wdir = os.path.join(args.root, wl.get("dir", name))
        flt = FILTERS.get(wl.get("filter"), lambda o: o)
        avail = [v for v in variants if os.path.exists(os.path.join(wdir, v))]
        env = dict(os.environ, **wl.get("env", {}))
        cwd = wl.get("cwd", wdir).replace("@DIR@", wdir)

        def cmd_for(v):
            binary = os.path.join(wdir, v)
            if args.stage_dir:
                binary = stage(binary, args.stage_dir)
            return expand(wl["eval"], binary, wdir)

        # Reference output of the original binary (also when it is not one of
        # the timed variants), then one warm-up run per variant.
        refbin = "orig" if os.path.exists(os.path.join(wdir, "orig")) else avail[0]
        *_, code, out = run_once(cmd_for(refbin), cwd, env)
        if code != 0:
            sys.exit(f"{name}/{refbin}: exit code {code}")
        reference = hashlib.sha256(flt(out)).hexdigest()
        for v in avail:
            for _ in range(args.warmup):
                *_, code, out = run_once(cmd_for(v), cwd, env)
            if code != 0 or hashlib.sha256(flt(out)).hexdigest() != reference:
                sys.exit(f"{name}/{v}: exit code {code} or output differs from {refbin}")

        samples = {v: {"wall": [], "user": [], "cpu": []} for v in avail}
        for r in range(args.rounds):
            order = avail[r % len(avail):] + avail[:r % len(avail)]
            for v in order:
                wall, user, sys_t, rss, code, out = run_once(cmd_for(v), cwd, env)
                h = hashlib.sha256(flt(out)).hexdigest()
                if code != 0 or h != reference:
                    sys.exit(f"{name}/{v}: bad run (exit {code})")
                samples[v]["wall"].append(wall)
                samples[v]["user"].append(user)
                samples[v]["cpu"].append(user + sys_t)
                writer.writerow([name, v, r, f"{wall:.6f}", f"{user:.6f}",
                                 f"{sys_t:.6f}", rss])
            raw.flush()
            print(f"[{name}] round {r + 1}/{args.rounds} done", flush=True)

        summary[name] = summarize(samples, args.metric)
        summary[name]["output_sha256"] = reference
        summary[name]["reference"] = refbin

    write_summary(args.out, summary, args.metric, args.rounds)


if __name__ == "__main__":
    main()
