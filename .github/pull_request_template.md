<!-- See CONTRIBUTING.md. -->

**What this changes and why**

**Checklist**

- [ ] `make lint` passes.
- [ ] Changes to the pass: the patch is exported to its existing file name,
      `make check-patch` passes, lit tests are added or updated, and
      `check-bolt` changes the result of no existing test.
- [ ] Without `--partial-inline`, `llvm-bolt` still writes byte-identical
      binaries to upstream (`scripts/verify_flag_off.sh`).
- [ ] Changes to results: they come from one complete run of
      `make experiments` in the image built from this commit.
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]`.
