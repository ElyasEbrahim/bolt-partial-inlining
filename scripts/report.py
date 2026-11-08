#!/usr/bin/env python3
"""Build the evaluation report from the timing results and the BOLT logs.

Inputs:
  <root>/<workload>/<variant>.log   llvm-bolt logs (with -dyno-stats)
  <root>/<workload>/<variant>       optimized binaries
  <results>/summary.json, raw.csv   produced by bench.py
Outputs (in <results>):
  REPORT.md, report.json, speedup.png, dynostats.png
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from workloads import WORKLOADS  # noqa: E402

DYNO_KEYS = ["executed instructions", "all function calls", "taken branches",
             "executed load instructions", "executed store instructions"]
PI_VARIANTS = ["bolt-pi", "bolt-pi-avg", "bolt-pi-nofe", "bolt-inl", "bolt-inl-pi"]
# Timing columns: the A/A control (byte-identical copy of bolt) first.
TIMING_VARIANTS = ["bolt-copy"] + PI_VARIANTS


def dynostats(log):
    """Program-wide dyno stats after all optimizations (last block)."""
    text = open(log, errors="replace").read()
    marker = "program-wide dynostats after all optimizations"
    pos = text.rfind(marker)
    if pos < 0:
        return {}
    blocks = text[pos:].split("\n\n")
    # blocks[1]: input stats, blocks[2]: stats after optimization (with deltas)
    block = blocks[2] if len(blocks) > 2 else blocks[1]
    stats = {}
    for line in block.splitlines():
        m = re.match(r"\s*(\d+) : (.+?)( \(.*\))?$", line)
        if m:
            stats[m.group(2)] = int(m.group(1))
    return stats


def pi_stats(log):
    text = open(log, errors="replace").read()
    out = {}
    m = re.search(r"partial inlining: (\d+) callees with a fast region \((\d+) with "
                  r"frame elision\); inlined (\d+) call sites \((\d+) with frame "
                  r"elision, (\d+) tail calls\), (\d+) instructions copied, (\d+) "
                  r"registers renamed", text)
    if m:
        keys = ["callees", "framed_callees", "sites", "framed_sites", "tail_sites",
                "copied_insns", "renamed_regs"]
        out.update(dict(zip(keys, map(int, m.groups()))))
    m = re.search(r"estimated (\d+) calls avoided on fast paths \(([\d.]+)% of "
                  r"profiled direct calls\), (\d+) slow-path calls", text)
    if m:
        out["fast_calls"] = int(m.group(1))
        out["fast_calls_pct"] = float(m.group(2))
        out["slow_calls"] = int(m.group(3))
    m = re.search(r"callees without a usable fast region: (.*)", text)
    if m:
        out["rejected"] = dict((k, int(v)) for k, v in
                               (kv.split("=") for kv in m.group(1).split()))
    return out


def text_size(binary):
    """Total size of the executable code sections."""
    try:
        out = subprocess.run(["llvm-readelf", "-S", "-W", binary], check=True,
                             capture_output=True, text=True).stdout
    except Exception:
        return None
    total = 0
    for line in out.splitlines():
        m = re.search(r"\]\s+(\.text\S*)\s+\S+\s+\S+\s+\S+\s+([0-9a-f]+)", line)
        if m:
            total += int(m.group(2), 16)
    return total


def bolt_time(path):
    try:
        return float(open(path).read().split()[0])
    except Exception:
        return None


def fmt_speedup(st):
    if "speedup_vs_bolt" not in st:
        return "-"
    lo, hi = st["speedup_ci95"]
    return f"{st['speedup_vs_bolt']:.3f} [{lo:.3f}, {hi:.3f}]"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="/work/out")
    ap.add_argument("--results", required=True)
    ap.add_argument("--summary", nargs="+",
                    help="summary.json files to merge (later files win); "
                         "default: <results>/summary.json")
    ap.add_argument("--icount", help="icount.json from icount.py")
    ap.add_argument("--pool", help="summary.json of pool_analysis.sh")
    args = ap.parse_args()
    summary = {}
    for f in args.summary or [os.path.join(args.results, "summary.json")]:
        summary.update(json.load(open(f)))
    icounts = json.load(open(args.icount)) if args.icount else {}

    report = {}
    for name, wl in WORKLOADS.items():
        d = os.path.join(args.root, wl.get("dir", name))
        if not os.path.isdir(d):
            continue
        entry = {"class": wl["class"], "timing": summary.get(name, {}).get("variants", {})}
        entry["dyno"] = {v: dynostats(os.path.join(d, f"{v}.log"))
                         for v in ["bolt"] + PI_VARIANTS
                         if os.path.exists(os.path.join(d, f"{v}.log"))}
        entry["pi"] = {v: pi_stats(os.path.join(d, f"{v}.log"))
                       for v in PI_VARIANTS if os.path.exists(os.path.join(d, f"{v}.log"))}
        entry["text_size"] = {v: text_size(os.path.join(d, v))
                              for v in ["orig", "bolt"] + PI_VARIANTS
                              if os.path.exists(os.path.join(d, v))}
        entry["bolt_time_s"] = {v: bolt_time(os.path.join(d, f"{v}.time"))
                                for v in ["bolt"] + PI_VARIANTS}
        report[name] = entry
    L = []
    L.append("# Evaluation report\n")
    L.append("Metric: user CPU time of the whole process. All variants of a "
             "workload run once per round in rotated order; speedup = median over "
             "rounds of t(bolt)/t(variant) (paired), with a 95% bootstrap "
             "confidence interval; p = two-sided Wilcoxon signed-rank test of "
             "`bolt-pi` against `bolt`. Every run's output was verified against "
             "the original binary.\n")
    L.append("## Speedup over the BOLT baseline\n")
    L.append("`bolt-copy` is a byte-identical copy of `bolt` (A/A control): it "
             "shows the size of differences the measurement reports when there is "
             "none.\n")
    L.append("| workload | class | rounds | bolt [s] | bolt-copy | bolt-pi | bolt-pi-avg | "
             "bolt-pi-nofe | bolt-inl | bolt-inl-pi | p (bolt-pi) |")
    L.append("|---|---|---:|---:|---|---|---|---|---|---|---:|")
    for name, e in report.items():
        t = e["timing"]
        if "bolt" not in t:
            continue
        p = t.get("bolt-pi", {}).get("wilcoxon_p")
        pstr = f"{p:.2g}" if p is not None else "-"
        L.append(f"| {name} | {e['class']} | {t['bolt']['n']} | "
                 f"{t['bolt']['median']:.3f} | " +
                 " | ".join(fmt_speedup(t.get(v, {})) for v in TIMING_VARIANTS) +
                 f" | {pstr} |")
    skip = [(n, e) for n, e in report.items() if "bolt-pi-skip" in e["timing"]]
    if skip:
        L.append("\n## Partial inlining without trivial callees\n")
        L.append("`bolt-pi-skip` is `bolt-pi` with the named callees excluded "
                 "(`-partial-inline-skip`): trivial functions that BOLT's existing "
                 "`-inline-all` inlines as well. The difference to `bolt` is the "
                 "share that only partial inlining achieves.\n")
        L.append("| workload | excluded | bolt-pi | bolt-pi-skip | bolt-inl | bolt-inl-pi "
                 "| calls avoided bolt-pi | calls avoided bolt-pi-skip | p (bolt-pi-skip) |")
        L.append("|---|---|---|---|---|---|---:|---:|---:|")
        for name, e in skip:
            d = os.path.join(args.root, WORKLOADS[name].get("dir", name))
            sk = open(os.path.join(d, "bolt-pi-skip.skipped")).read().strip()
            ps = pi_stats(os.path.join(d, "bolt-pi-skip.log"))
            t = e["timing"]
            p = t["bolt-pi-skip"].get("wilcoxon_p")
            L.append(f"| {name} | `{sk}` | " + " | ".join(
                fmt_speedup(t.get(v, {})) for v in
                ["bolt-pi", "bolt-pi-skip", "bolt-inl", "bolt-inl-pi"]) +
                f" | {e['pi'].get('bolt-pi', {}).get('fast_calls_pct', 0):.2f}% | "
                f"{ps.get('fast_calls_pct', 0):.2f}% | {p:.2g} |")
    if icounts:
        L.append("\n## Executed instructions (valgrind, smaller inputs; change vs. bolt)\n")
        L.append("All instructions of the process; every variant is executed from "
                 "the same path (see scripts/icount.py).\n")
        vs = ["orig", "bolt-pi", "bolt-pi-nofe", "bolt-inl", "bolt-inl-pi"]
        L.append("| workload | bolt [instructions] | " + " | ".join(vs) + " |")
        L.append("|---|---:|" + "---:|" * len(vs))
        for name, c in icounts.items():
            b = c.get("bolt")
            if not b:
                continue
            L.append(f"| {name} | {b:,} | " + " | ".join(
                f"{100.0 * (c[v] - b) / b:+.2f}%" if v in c else "-" for v in vs) + " |")
    if args.pool:
        pool = json.load(open(args.pool))["pool"]["variants"]
        rounds = next(iter(pool.values()))["n"]
        L.append(f"\n## pool: layout interaction analysis ({rounds} rounds)\n")
        L.append("| variant | median [s] | speedup vs bolt [95% CI] | p |")
        L.append("|---|---:|---|---:|")
        for v, st in pool.items():
            L.append(f"| {v} | {st['median']:.4f} | {fmt_speedup(st)} | "
                     f"{st.get('wilcoxon_p', float('nan')):.2g} |")
    L.append("\n## What the pass did (bolt-pi)\n")
    L.append("| workload | callees with fast region | sites | with frame elision "
             "| tail-call sites | insns copied | regs renamed | fast-path calls "
             "avoided (% of direct calls) |")
    L.append("|---|---:|---:|---:|---:|---:|---:|---:|")
    for name, e in report.items():
        s = e["pi"].get("bolt-pi", {})
        if not s:
            continue
        L.append(f"| {name} | {s.get('callees', 0)} | {s.get('sites', 0)} | "
                 f"{s.get('framed_sites', 0)} | {s.get('tail_sites', 0)} | "
                 f"{s.get('copied_insns', 0)} | {s.get('renamed_regs', 0)} | "
                 f"{s.get('fast_calls', 0)} ({s.get('fast_calls_pct', 0):.2f}%) |")
    L.append("\n## Profile-estimated dynamic effect (BOLT dyno-stats, bolt-pi vs bolt)\n")
    L.append("| workload | " + " | ".join(DYNO_KEYS) + " |")
    L.append("|---|" + "---:|" * len(DYNO_KEYS))
    for name, e in report.items():
        b, p = e["dyno"].get("bolt", {}), e["dyno"].get("bolt-pi", {})
        if not b or not p:
            continue
        cells = []
        for k in DYNO_KEYS:
            if b.get(k):
                cells.append(f"{100.0 * (p.get(k, 0) - b[k]) / b[k]:+.2f}%")
            else:
                cells.append("-")
        L.append(f"| {name} | " + " | ".join(cells) + " |")
    L.append("\n## Code size and BOLT processing time\n")
    L.append("| workload | .text bolt [B] | .text bolt-pi [B] | growth | "
             "llvm-bolt time bolt [s] | bolt-pi [s] |")
    L.append("|---|---:|---:|---:|---:|---:|")
    for name, e in report.items():
        sb, sp = e["text_size"].get("bolt"), e["text_size"].get("bolt-pi")
        tb, tp = e["bolt_time_s"].get("bolt"), e["bolt_time_s"].get("bolt-pi")
        if sb and sp:
            L.append(f"| {name} | {sb} | {sp} | {100.0 * (sp - sb) / sb:+.2f}% | "
                     f"{tb} | {tp} |")
    L.append("\n## Rejection reasons (callees of hot call sites without a usable "
             "fast region)\n")
    reasons = ["not-simple", "no-profile", "entry-not-copyable", "no-fast-exit",
               "stack-access", "frame-mismatch", "side-effect", "reg-clobber",
               "no-scratch", "too-large", "cold-fast-path"]
    L.append("| workload | " + " | ".join(reasons) + " |")
    L.append("|---|" + "---:|" * len(reasons))
    for name, e in report.items():
        rej = e["pi"].get("bolt-pi", {}).get("rejected", {})
        L.append(f"| {name} | " + " | ".join(str(rej.get(r, 0)) for r in reasons) + " |")
    open(os.path.join(args.results, "REPORT.md"), "w").write("\n".join(L) + "\n")
    json.dump(dict(report, _icount=icounts),
              open(os.path.join(args.results, "report.json"), "w"), indent=1)

    try:
        plot(report, args.results)
    except Exception as ex:  # matplotlib missing or headless issues
        print("plotting skipped:", ex)
    print("\n".join(L))


def plot(report, outdir):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    names = [n for n, e in report.items()
             if not n.startswith("_") and "bolt-pi" in e["timing"]]
    variants = [("bolt-copy", "identical copy of bolt (control)"),
                ("bolt-pi", "bolt + partial inlining"),
                ("bolt-pi-nofe", "  without frame elision"),
                ("bolt-pi-avg", "  average profile model"),
                ("bolt-inl", "bolt + existing -inline-all")]
    colors = ["#9a9a9a", "#2a6fdb", "#8fb3ee", "#b9c7d9", "#d98a2a"]
    fig, ax = plt.subplots(figsize=(12, 4.8))
    width = 0.8 / len(variants)
    for i, (v, label) in enumerate(variants):
        ys, lo, hi, xs = [], [], [], []
        for j, n in enumerate(names):
            st = report[n]["timing"].get(v)
            if not st or "speedup_vs_bolt" not in st:
                continue
            s = st["speedup_vs_bolt"]
            ys.append(s)
            lo.append(s - st["speedup_ci95"][0])
            hi.append(st["speedup_ci95"][1] - s)
            xs.append(j + (i - (len(variants) - 1) / 2) * width)
        ax.bar(xs, ys, width, yerr=[lo, hi], capsize=2, label=label,
               color=colors[i], edgecolor="none")
    ax.axhline(1.0, color="#333", linewidth=0.8)
    ax.set_xticks(range(len(names)))
    ax.set_xticklabels(names, rotation=30, ha="right")
    ax.set_ylabel("speedup over BOLT baseline (higher is better)")
    ax.set_yscale("log")
    ax.set_yticks([0.9, 1.0, 1.1, 1.25, 1.5, 2.0, 2.5])
    ax.get_yaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
    ax.legend(frameon=False, fontsize=9, ncol=2)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_title("Apple M3 Max (Linux/AArch64 VM), user CPU time, median with 95% CI")
    fig.tight_layout()
    fig.savefig(os.path.join(outdir, "speedup.png"), dpi=150)

    fig, ax = plt.subplots(figsize=(12, 4.2))
    keys = ["executed instructions", "all function calls",
            "executed load instructions", "executed store instructions"]
    width = 0.8 / len(keys)
    for i, k in enumerate(keys):
        xs, ys = [], []
        for j, n in enumerate(names):
            b, p = report[n]["dyno"].get("bolt", {}), report[n]["dyno"].get("bolt-pi", {})
            if b.get(k):
                xs.append(j + (i - (len(keys) - 1) / 2) * width)
                ys.append(100.0 * (p.get(k, 0) - b[k]) / b[k])
        ax.bar(xs, ys, width, label=k)
    ax.axhline(0, color="#333", linewidth=0.8)
    ax.set_xticks(range(len(names)))
    ax.set_xticklabels(names, rotation=30, ha="right")
    ax.set_ylabel("change vs. bolt [%] (profile-estimated)")
    ax.legend(frameon=False, fontsize=9, ncol=4)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(os.path.join(outdir, "dynostats.png"), dpi=150)


if __name__ == "__main__":
    main()
