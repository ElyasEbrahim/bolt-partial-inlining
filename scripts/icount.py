#!/usr/bin/env python3
"""Deterministic instruction counts of the BOLT variants (valgrind cachegrind,
--cache-sim=no): all instructions executed by the process.

Every variant is executed from the same path (a fresh copy at
<stage-dir>/prog), as in bench.py. The path of the executable determines where
the initial stack begins (argv[0] and AT_EXECFN are copied onto it), and some
programs behave differently depending on stack addresses. Lua, for example,
caches C strings in a table indexed by their address (luaS_new), and many of
them are stack buffers: run under their own file names, two BOLT variants
that differ only in function order executed up to 0.6% more or fewer
instructions; run from the same path they execute exactly the same number.

Per-function or per-object breakdowns are not reported: valgrind cannot read
the symbols of the code segment that BOLT adds ("ELF section outside all
mapped regions") and attributes that code to unrelated functions.

Output: <out>/icount.json and a table on stdout.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bench import stage  # noqa: E402
from workloads import ICOUNT, WORKLOADS, expand  # noqa: E402


def icount(cmd, env, cwd):
    p = subprocess.run(["valgrind", "--tool=cachegrind", "--cache-sim=no",
                        "--cachegrind-out-file=/dev/null"] + cmd,
                       env=env, cwd=cwd, stdout=subprocess.DEVNULL,
                       stderr=subprocess.PIPE, text=True)
    m = re.search(r"I\s+refs:\s+([\d,]+)", p.stderr)
    if p.returncode != 0 or not m:
        raise RuntimeError(f"valgrind failed for {cmd}: {p.stderr[-500:]}")
    return int(m.group(1).replace(",", ""))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="/work/out")
    ap.add_argument("--out", required=True)
    ap.add_argument("--variants",
                    default="orig,bolt,bolt-pi,bolt-pi-nofe,bolt-inl,bolt-inl-pi,bolt-pi-skip")
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--stage-dir", help="directory for the copy that is executed "
                                        "(default: a temporary directory)")
    args = ap.parse_args()
    stage_dir = args.stage_dir or tempfile.mkdtemp(prefix="icount.")
    res = {}
    for name in args.only or ICOUNT:
        wl = WORKLOADS[name]
        d = os.path.join(args.root, wl.get("dir", name))
        env = dict(os.environ, **wl.get("env", {}))
        res[name] = {}
        for v in args.variants.split(","):
            b = os.path.join(d, v)
            if not os.path.exists(b):
                continue
            cmd = expand(ICOUNT[name], stage(b, stage_dir), d)
            res[name][v] = icount(cmd, env, d)
        base = res[name]["bolt"]
        print(name, " ".join(f"{v}={c} ({100.0 * (c - base) / base:+.3f}%)"
                             for v, c in res[name].items()), flush=True)
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "icount.json"), "w") as f:
        json.dump(res, f, indent=1)


if __name__ == "__main__":
    main()
