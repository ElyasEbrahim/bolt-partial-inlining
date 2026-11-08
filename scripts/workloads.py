"""Evaluation workloads.

Every entry describes how to run one workload binary for measurement:
  eval:   command line; @BIN@ is replaced by the variant binary and @DIR@ by
          the workload output directory (<root>/<name>).
  cwd:    working directory (default: @DIR@).
  filter: optional function applied to stdout before comparing outputs.
  class:  'target' (expected to benefit), 'neutral' (no applicable pattern
          or unsafe pattern; must not regress) or 'adversarial'.
The training commands that produce the profiles are in prepare_*.sh and use
different (smaller) inputs than the evaluation commands below.

Paths: @WL@ is the benchmarks/realworld directory of this repository and the
real-world programs and corpora are expected in $RW (default /work/rw, see
benchmarks/realworld/build.sh and scripts/prepare_realworld.sh).
"""
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WL = os.path.join(REPO, "benchmarks", "realworld")
RW = os.environ.get("RW", "/work/rw")
# CPython randomizes string hashing per process; a fixed seed makes the
# training profile, and therefore the BOLT output, reproducible.
PYENV = {"PYTHONHOME": f"{RW}/cpython/inst", "PYTHONHASHSEED": "0"}

WORKLOADS = {
    # ---- microbenchmarks ---------------------------------------------------
    "bufwrite": {"class": "target", "eval": ["@BIN@", "300000000"]},
    "memo": {"class": "target", "eval": ["@BIN@", "200000000", "20"]},
    "trace": {"class": "target", "eval": ["@BIN@", "300000000"]},
    "pool": {"class": "target", "eval": ["@BIN@", "200000000"]},
    "mixed": {"class": "adversarial", "eval": ["@BIN@", "60000000"]},
    "memo-lowhit": {"class": "neutral", "eval": ["@BIN@", "60000000", "700"]},
    "unsafe": {"class": "neutral", "eval": ["@BIN@", "200000000"]},
    "compute": {"class": "neutral", "eval": ["@BIN@", "40"]},
    # ---- real-world programs -------------------------------------------------
    "sqlite": {"class": "real", "eval": ["@BIN@", "--size", "60", "--memdb"],
               "filter": "speedtest"},
    "lua": {"class": "real",
            "eval": ["@BIN@", "@WL@/lua/bench.lua", "6"]},
    "cpython": {"class": "real",
                "eval": ["@BIN@", "-S", "@WL@/python/bench.py", "8"],
                "env": PYENV},
    "zstd-compress": {"class": "real", "dir": "zstd",
                      "eval": ["@BIN@", "-q", "-3", "-c", "@RW@/corpus/eval4.txt"]},
    # Decompressed data is checked by zstd itself (frames carry an XXH64
    # content checksum by default; a mismatch fails the run).
    "zstd-decompress": {"class": "real", "dir": "zstd",
                        "eval": ["@BIN@", "-q", "-d", "-f", "-o", "/dev/null",
                                 "@RW@/corpus/eval16.txt.zst"]},
    "jq": {"class": "real",
           "eval": ["@BIN@", "-f", "@WL@/jq/bench.jq", "@RW@/corpus/data-eval.json"]},
    "libxml2": {"class": "real",
                "eval": ["@BIN@", "--noout", "--xpath", "count(//item[@kind='b'])",
                         "@RW@/corpus/data-eval.xml"]},
}

# Smaller inputs for the instruction counts measured with valgrind (icount.py).
ICOUNT = {
    "bufwrite": ["@BIN@", "3000000"],
    "memo": ["@BIN@", "2000000", "20"],
    "trace": ["@BIN@", "3000000"],
    "pool": ["@BIN@", "2000000"],
    "mixed": ["@BIN@", "600000"],
    "memo-lowhit": ["@BIN@", "600000", "700"],
    "unsafe": ["@BIN@", "2000000"],
    "compute": ["@BIN@", "2", "100"],
    "sqlite": ["@BIN@", "--size", "5", "--memdb"],
    "lua": ["@BIN@", "@WL@/lua/bench.lua", "1"],
    "cpython": ["@BIN@", "-S", "@WL@/python/bench.py", "1"],
    "zstd-compress": ["@BIN@", "-q", "-3", "-c", "@RW@/corpus/eval.txt"],
    "zstd-decompress": ["@BIN@", "-q", "-d", "-c", "@RW@/corpus/eval.txt.zst"],
    "jq": ["@BIN@", "-f", "@WL@/jq/bench.jq", "@RW@/corpus/data-icount.json"],
    "libxml2": ["@BIN@", "--noout", "--xpath", "count(//item[@kind='b'])",
                "@RW@/corpus/data-icount.xml"],
}


def expand(args, binary, wdir=""):
    """Substitute @BIN@, @DIR@, @WL@ and @RW@ in a command line."""
    return [a.replace("@BIN@", binary).replace("@DIR@", wdir)
             .replace("@WL@", WL).replace("@RW@", RW) for a in args]


def strip_timing(out: bytes) -> bytes:
    """Remove the per-test timings that speedtest1 prints."""
    return re.sub(rb"\s+[0-9]+\.[0-9]+s\s*$", b"", out, flags=re.M)


FILTERS = {"speedtest": strip_timing}
