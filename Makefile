# Common tasks. All of them run in Docker; see README.md.
#
#   make image          build the evaluation image (upstream + patched BOLT, workloads)
#   make experiments    run the complete evaluation and update results/ (AArch64 host)
#   make check-bolt     extract and compare the BOLT test results of both builds
#   make x86-validate   functional validation on x86-64 under emulation
#   make check-patch    check that the patch applies to the pinned LLVM commit
#   make lint           shellcheck and pyflakes for the scripts

IMAGE       ?= bolt-partial-inline:latest
LLVM_COMMIT := $(shell cat patches/LLVM_COMMIT)
PATCH       := $(wildcard patches/0001-*.patch)
# Local scratch directory (LLVM checkout, extracted binaries, raw results).
WORK        := $(CURDIR)/.work

.PHONY: image experiments check-bolt x86-validate check-patch lint llvm-src clean

image:
	docker build -t $(IMAGE) -f docker/Dockerfile .

# One complete evaluation run. Its output replaces the generated files in
# results/; results/README.md, check-bolt/ and x86-validation.txt are kept.
# seccomp=unconfined lets the training runs disable ASLR (setarch -R) so that
# profiles and BOLT outputs are reproducible; the tmpfs at /stage holds the
# fresh copy of the binary that every timed run executes (scripts/bench.py).
experiments:
	mkdir -p $(WORK)/results
	docker run --rm --security-opt seccomp=unconfined --tmpfs /stage:rw,exec,size=1g \
	  -e IMAGE_ID=$$(docker image inspect --format '{{.Id}}' $(IMAGE)) \
	  -v $(WORK)/results:/work/results $(IMAGE) scripts/run_experiments.sh
	find results -mindepth 1 -maxdepth 1 ! -name README.md ! -name check-bolt \
	  ! -name x86-validation.txt -exec rm -rf {} +
	cp -R $(WORK)/results/. results/

# BOLT lit test results of the upstream and the patched build in the image.
check-bolt:
	mkdir -p results/check-bolt
	docker run --rm -v $(CURDIR)/results/check-bolt:/x $(IMAGE) bash -c '\
	  for v in baseline patched; do \
	    cp /opt/bolt-$$v/check-bolt.log /x/$$v-check-bolt.log; \
	    cp /opt/bolt-$$v/lit-results.json /x/$$v-lit-results.json; done'
	python3 scripts/compare_lit.py results/check-bolt/baseline-lit-results.json \
	  results/check-bolt/patched-lit-results.json > results/check-bolt/comparison.md

# Sparse checkout of the pinned LLVM commit (only bolt/ is needed here).
llvm-src:
	test -d $(WORK)/llvm-project || ( \
	  git init -q $(WORK)/llvm-project && cd $(WORK)/llvm-project && \
	  git remote add origin https://github.com/llvm/llvm-project.git && \
	  git sparse-checkout set bolt && \
	  git fetch -q --depth 1 --filter=blob:none origin $(LLVM_COMMIT) && \
	  git checkout -q FETCH_HEAD )

check-patch: llvm-src
	cd $(WORK)/llvm-project && git apply --check $(CURDIR)/$(PATCH) && \
	  echo "patch applies to $(LLVM_COMMIT)"

x86-validate: llvm-src
	mkdir -p $(WORK)/bin
	docker run --rm -v $(WORK)/bin:/x $(IMAGE) cp /opt/bolt/bin/llvm-bolt /x/
	scripts/x86_validate.sh . $(WORK)/bin $(WORK)/llvm-project/bolt/runtime \
	  | grep -v '^debconf\|^dpkg-preconfigure' | tee results/x86-validation.txt

lint:
	docker run --rm -v $(CURDIR):/r -w /r ubuntu:24.04 bash -c '\
	  apt-get update -qq >/dev/null && \
	  apt-get install -y -qq shellcheck python3-pyflakes >/dev/null && \
	  shellcheck -S warning scripts/*.sh benchmarks/realworld/build.sh && \
	  python3 -m pyflakes scripts/*.py benchmarks/realworld/python/bench.py benchmarks/realworld/datagen.py'

clean:
	rm -rf $(CURDIR)/.work
