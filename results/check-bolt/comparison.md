# BOLT test suite: upstream vs. patched

| Result | upstream | patched |
|---|---:|---:|
| FAIL | 2 | 2 |
| PASS | 710 | 719 |
| UNSUPPORTED | 141 | 141 |
| XFAIL | 1 | 1 |
| total | 854 | 863 |

Tests whose result changed: 0

Tests added by the patch: 9
- BOLT :: AArch64/partial-inline-frame-elision.s: PASS
- BOLT :: AArch64/partial-inline-frameless.s: PASS
- BOLT :: AArch64/partial-inline-loop.s: PASS
- BOLT :: AArch64/partial-inline-pauth.s: PASS
- BOLT :: AArch64/partial-inline-reject.s: PASS
- BOLT :: AArch64/partial-inline-save-regs.s: PASS
- BOLT :: AArch64/partial-inline-sites.s: PASS
- BOLT :: X86/partial-inline.s: PASS
- BOLT :: runtime/AArch64/partial-inline.c: PASS

Tests removed: 0

Failing in the patched build: BOLT :: AArch64/dwarf5-duplicate-file-names.s, BOLT :: AArch64/icp-inline.c

Failing in the upstream build: BOLT :: AArch64/dwarf5-duplicate-file-names.s, BOLT :: AArch64/icp-inline.c
