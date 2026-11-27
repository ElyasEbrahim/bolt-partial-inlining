#!/usr/bin/env python3
"""Which calls of the real programs does the pass reach, and what stops it?

For every real program in <root> (variants built by prepare_realworld.sh) the
script reads the instrumentation profile and runs llvm-bolt a few times. No
timing is involved, so the output is deterministic.

  1. Function entries in the profile, and how many of them the profile cannot
     attribute to a caller ("[unknown]"): calls from functions that BOLT
     cannot disassemble into a control-flow graph (interpreter loops with
     computed gotos) and from outside the binary. No BOLT pass can change
     these call sites.
  2. Direct calls at call sites that the pass can transform, and the share
     whose fast path it copies.
  3. The callees of hot call sites that it rejects, by reason, weighted by
     their execution counts (llvm-bolt -v=2).
  4. The effect of the region size limits and of the two extensions (loops,
     saved registers) on coverage, on BOLT's estimate of the executed
     instructions (dyno stats) and on the code size.

  coverage.py --root /work/out --out <dir>     writes <dir>/coverage.json
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from report import dynostats, text_size  # noqa: E402

PROGRAMS = ["sqlite", "lua", "cpython", "zstd", "jq", "libxml2", "clang"]
LAYOUT = ["-reorder-blocks=ext-tsp", "-reorder-functions=cdsort", "-split-functions",
          "-split-all-cold", "-split-eh", "-icf=1", "-dyno-stats"]
NOEXT = ["-partial-inline-loops=false", "-partial-inline-save-regs=false"]


def limits(insns, blocks):
    return [f"-partial-inline-max-insns={insns}", f"-partial-inline-max-blocks={blocks}"]


# name -> extra options; "24/8" is the default configuration of the pass.
CONFIGS = [("without extensions", NOEXT), ("16/6", limits(16, 6)), ("24/8", []),
           ("32/8", limits(32, 8)), ("40/12", limits(40, 12)), ("64/16", limits(64, 16))]


def profile_entries(path):
    """Transfers to the entry of another function, by caller."""
    total, unknown = 0, 0
    callees = collections.Counter()
    for line in open(path, errors="replace"):
        f = line.split()
        if len(f) != 8 or f[5] != "0" or f[1] == f[4]:
            continue
        n = int(f[7])
        total += n
        if f[1] == "[unknown]":
            unknown += n
            callees[f[4]] += n
    return total, unknown, callees.most_common(3)


def bolt(bolt_bin, d, out, extra):
    log = out + ".log"
    with open(log, "w") as f:
        subprocess.run([os.path.join(bolt_bin, "llvm-bolt"), os.path.join(d, "orig"),
                        "-o", out, "-data", os.path.join(d, "prof.fdata")] + LAYOUT + extra,
                       stdout=f, stderr=subprocess.STDOUT, check=True)
    return log


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default="/work/out")
    ap.add_argument("--out", required=True)
    ap.add_argument("--bolt-bin", default=os.environ.get("BOLT_BIN", "/opt/bolt/bin"))
    ap.add_argument("--only", nargs="*", default=PROGRAMS)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="coverage.")
    res = {}
    for w in args.only:
        d = os.path.join(args.root, w)
        if not os.path.exists(os.path.join(d, "prof.fdata")):
            continue
        total, unknown, top = profile_entries(os.path.join(d, "prof.fdata"))
        base_bin = os.path.join(tmp, "base")
        base = dynostats(bolt(args.bolt_bin, d, base_bin, []))
        base_text = text_size(base_bin)
        r = {"entries": total, "entries_unknown": unknown, "top_unknown": top,
             "configs": {}, "rejected": {}}
        for name, extra in CONFIGS:
            out = os.path.join(tmp, "pi")
            log = bolt(args.bolt_bin, d, out, ["-partial-inline", "-v=2"] + extra)
            text = open(log, errors="replace").read()
            dyn = dynostats(log)
            m = re.search(r"estimated (\d+) calls avoided on fast paths \(([\d.]+)% of "
                          r"profiled direct calls\)", text)
            avoided, pct = (int(m.group(1)), float(m.group(2))) if m else (0, 0.0)
            c = {"sites": int(re.search(r"inlined (\d+) call sites", text).group(1)),
                 "avoided": avoided, "avoided_pct": pct,
                 "insns_pct": 100.0 * (dyn["executed instructions"] - base["executed instructions"])
                 / base["executed instructions"],
                 "text_pct": 100.0 * (text_size(out) - base_text) / base_text}
            r["configs"][name] = c
            if name != "24/8":
                continue
            # Details for the default configuration.
            r["direct_calls"] = round(avoided / pct * 100) if pct else None
            by = collections.defaultdict(list)
            for fn, reason, n in re.findall(
                    r"no fast region in (.+?): ([a-z-]+) \(exec count (\d+)\)", text):
                by[reason].append((int(n), fn))
            for reason, lst in by.items():
                lst.sort(reverse=True)
                r["rejected"][reason] = {"callees": len(lst),
                                         "executions": sum(n for n, _ in lst),
                                         "top": [(fn, n) for n, fn in lst[:3]]}
        res[w] = r
        print(w, json.dumps(r["configs"]["24/8"]), flush=True)
    json.dump(res, open(os.path.join(args.out, "coverage.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
