#!/usr/bin/env python3
"""Hand-written variants of the hot loop of the 'pool' microbenchmark.

BOLT does not place single instructions, so the question which property of
the partially inlined loop makes it slow (design document, Section 5.5) is
studied on assembly variants of main(): the compiler's output for
benchmarks/micro/pool/main.c (pool_loop/main.template.s) with the loop
replaced by the instruction sequences that llvm-bolt emits, in several block
orders and with small edits. pool_analysis.sh times the variants that mirror
a BOLT output next to that output, which validates the method, and checks the
output of every variant.

  pool_loop.py <out-dir> [--driver rng|counter] [--placement]

writes <out-dir>/<variant>.s:
  hw-base      loop of 'bolt': calls pool_free and pool_alloc
  hw-base-head+1  hw-base with one nop at the start of the loop head
  hw-straight  loop of 'bolt-pi': both fast paths inlined, ext-tsp block order
  hw-norb      the same blocks in the original order (pa-norb-pi)
  hw-cache     the same blocks with -reorder-blocks=cache (pa-cache-pi)
  hw-gap+N     hw-straight with N nops between the two inlined regions
  hw-tail+4    hw-straight with 4 nops after the second region instead
  hw-samebase  hw-straight, second region addresses the pool through x0 like
               the first one (the register copy 'mov x11, x0' is kept as a
               dead instruction: same instruction count)
  hw-short1    the same without the copy: one instruction fewer
  hw-short2    and with x0 set once per iteration: two instructions fewer
  hw-fwd1      hw-straight with the reload of p->live in the second region
               replaced by a register copy. At the binary level this is the
               only one of the three reloads that is provably redundant (no
               store in between)
  hw-fwd3      all three reloads (p->free, n->next, p->live) replaced by
               register copies, as a compiler does after inlining with
               type-based alias information
--placement instead writes hw-base-pNN and hw-straight-pNN, NN = 00..15: NN
  nops in front of the loop, which are not executed. Every instruction of
  the loop is shifted by 4*NN bytes; the executed instructions do not change.
--driver counter: the loop computes slot = i & (w - 1) instead of
  slot = rng % w, see pool_analysis.sh. Requires a power of two as window.
"""
import argparse
import os

HERE = os.path.dirname(os.path.abspath(__file__))

RNG = """\teor\tx8, x25, x25, lsr #12
\teor\tx8, x8, x8, lsl #25
\teor\tx25, x8, x8, lsr #27
\tmul\tx8, x25, x24
"""
SLOT = {
    "rng": RNG + "\tudiv\tx9, x8, x20\n\tmsub\tx26, x9, x20, x8\n",
    "counter": "\tand\tx26, x23, x24\n",
}
# Executed once before the loop (the compiler hoists w - 1 as well).
PREHEADER = {"rng": "", "counter": "\tsub\tx24, x20, #1\n"}
# Fast path of pool_free as copied by the pass (x0 = pool, x1 = object).
FREE = """\tldr\tx8, [x0]
\tldr\tx9, [x0, #0x18]
\tstr\tx1, [x0]
\tstr\tx8, [x1]
\tsub\tx8, x9, #0x1
\tstr\tx8, [x0, #0x18]
"""
# Fast path of pool_alloc as copied by the pass (x19 renamed to x11).
ALLOC = """\tldr\tx8, [x0]
\tmov\tx11, x0
\tcbz\tx8, .Lslow
\tldr\tx10, [x8]
\tldr\tx9, [x11, #0x18]
\tstr\tx10, [x11]
\tmov\tx0, x8
\tadd\tx9, x9, #0x1
\tstr\tx9, [x11, #0x18]
"""
ALLOC_SHORT = """\tldr\tx8, [x0]
\tcbz\tx8, .Lslow
\tldr\tx10, [x8]
\tldr\tx9, [x0, #0x18]
\tstr\tx10, [x0]
\tadd\tx9, x9, #0x1
\tstr\tx9, [x0, #0x18]
\tmov\tx0, x8
"""
ALLOC_SAMEBASE = ALLOC_SHORT.replace("\tcbz\t", "\tmov\tx11, x0\n\tcbz\t")
TAIL = """.Ltail:
\teor\tx8, x26, x23
\tstr\tx23, [x0, #8]
\tadd\tx23, x23, #1
\tcmp\tx19, x23
\tadd\tx21, x8, x21
\tstr\tx0, [x22, x26, lsl #3]
\tb.eq\t.LBB0_10
"""
SLOW = ".Lslow:\n\tbl\tpool_alloc\n\tb\t.Ltail\n"
ARG = "\tmov\tx0, sp\n"
LATCH = "\tcbz\tx1, .Lalloc\n\tb\t.Lfree\n"


def head(driver, pad=0):
    return (".LBB0_8:\n" + "\tnop\n" * pad + SLOT[driver] +
            "\tldr\tx1, [x22, x26, lsl #3]\n")


def base(d, pad=0):
    return (".Lfree:\n" + ARG + "\tbl\tpool_free\n.Lalloc:\n" + ARG +
            "\tbl\tpool_alloc\n" + TAIL + head(d, pad) + LATCH)


def straight(d, alloc=ALLOC, gap=0, tail=0):
    return (".Lfree:\n" + ARG + FREE + "\tnop\n" * gap + ".Lalloc:\n" + ARG +
            alloc + "\tnop\n" * tail + TAIL + head(d) + LATCH + SLOW)


def short2(d):
    return (".Lfree:\n" + FREE + ".Lalloc:\n" + ALLOC_SHORT + TAIL + head(d) +
            ARG + LATCH + SLOW)


def norb(d):
    return (".Lpre:\n" + ARG + "\tb\t.Lallocb\n" + head(d) +
            "\tcbz\tx1, .Lpre\n" + ARG + "\tb\t.Lfreeb\n" + TAIL +
            "\tb\t.LBB0_8\n" + SLOW + ".Lallocb:\n" + ALLOC + "\tb\t.Ltail\n" +
            ".Lret:\n\tb\t.Lpre\n.Lfreeb:\n" + FREE + "\tb\t.Lret\n")


def cache(d):
    return (".Lalloc:\n" + ARG + ALLOC + TAIL + head(d) +
            "\tcbz\tx1, .Lalloc\n" + ARG + FREE + "\tb\t.Lalloc\n" + SLOW)


def forward(d, all_loads):
    free = FREE.replace("sub\tx8, x9, #0x1", "sub\tx12, x9, #0x1") \
               .replace("str\tx8, [x0, #0x18]", "str\tx12, [x0, #0x18]")
    alloc = ALLOC.replace("ldr\tx9, [x11, #0x18]", "mov\tx9, x12")
    arg = ARG
    if all_loads:
        free = free.replace("ldr\tx8, [x0]", "ldr\tx13, [x0]") \
                   .replace("str\tx8, [x1]", "str\tx13, [x1]")
        alloc = alloc.replace("ldr\tx8, [x0]", "mov\tx8, x1") \
                     .replace("ldr\tx10, [x8]", "mov\tx10, x13")
        arg = ""
    # The first iterations that find an empty slot enter at .Lalloc.
    return (".Lfree:\n" + ARG + free + arg + alloc + TAIL + head(d) + LATCH +
            ".Lalloc:\n" + ARG + ALLOC + "\tb\t.Ltail\n" + SLOW)


VARIANTS = {
    "hw-base": base,
    "hw-base-head+1": lambda d: base(d, pad=1),
    "hw-straight": straight,
    "hw-norb": norb,
    "hw-cache": cache,
    "hw-tail+4": lambda d: straight(d, tail=4),
    "hw-samebase": lambda d: straight(d, alloc=ALLOC_SAMEBASE),
    "hw-short1": lambda d: straight(d, alloc=ALLOC_SHORT),
    "hw-short2": short2,
    "hw-fwd1": lambda d: forward(d, False),
    "hw-fwd3": lambda d: forward(d, True),
}
for _n in (1, 2, 3, 4, 5, 6, 8, 16):
    VARIANTS[f"hw-gap+{_n}"] = lambda d, n=_n: straight(d, gap=n)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out")
    ap.add_argument("--driver", default="rng", choices=sorted(SLOT))
    ap.add_argument("--placement", action="store_true")
    args = ap.parse_args()
    template = open(os.path.join(HERE, "pool_loop", "main.template.s")).read()
    entry = "\tb\t.LBB0_8\n@LOOP@\n"
    assert template.count(entry) == 1
    os.makedirs(args.out, exist_ok=True)
    if args.placement:
        bodies = {f"{name}-p{p:02d}": "\tnop\n" * p + VARIANTS[name](args.driver)
                  for name in ("hw-base", "hw-straight") for p in range(16)}
    else:
        bodies = {name: f(args.driver) for name, f in VARIANTS.items()}
    for name, body in bodies.items():
        with open(os.path.join(args.out, name + ".s"), "w") as f:
            f.write(template.replace(
                entry, PREHEADER[args.driver] + "\tb\t.LBB0_8\n" + body))
    print(" ".join(bodies))


if __name__ == "__main__":
    main()
