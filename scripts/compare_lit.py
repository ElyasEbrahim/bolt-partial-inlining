#!/usr/bin/env python3
"""Compare two llvm-lit JSON result files (llvm-lit --output) test by test.

  compare_lit.py upstream.json patched.json > comparison.md

Exits with status 1 if the result of an existing test changed or a test
disappeared.
"""
import collections
import json
import sys


def load(path):
    return {t["name"]: t["code"] for t in json.load(open(path))["tests"]}


def main():
    base, new = load(sys.argv[1]), load(sys.argv[2])
    cb, cn = collections.Counter(base.values()), collections.Counter(new.values())
    print("# BOLT test suite: upstream vs. patched\n")
    print("| Result | upstream | patched |\n|---|---:|---:|")
    for code in sorted(set(cb) | set(cn)):
        print(f"| {code} | {cb[code]} | {cn[code]} |")
    print(f"| total | {len(base)} | {len(new)} |\n")
    changed = sorted(n for n in base if n in new and base[n] != new[n])
    added = sorted(n for n in new if n not in base)
    removed = sorted(n for n in base if n not in new)
    print(f"Tests whose result changed: {len(changed)}")
    for n in changed:
        print(f"- {n}: {base[n]} -> {new[n]}")
    print(f"\nTests added by the patch: {len(added)}")
    for n in added:
        print(f"- {n}: {new[n]}")
    print(f"\nTests removed: {len(removed)}")
    for n in removed:
        print(f"- {n}")
    failing = sorted(n for n, c in new.items() if c in ("FAIL", "XPASS"))
    failing_base = sorted(n for n, c in base.items() if c in ("FAIL", "XPASS"))
    print("\nFailing in the patched build: " + (", ".join(failing) or "none"))
    print("\nFailing in the upstream build: " + (", ".join(failing_base) or "none"))
    return 1 if changed or removed else 0


if __name__ == "__main__":
    sys.exit(main())
