# Cairn's example apps. `cairn build --app <App>` builds each: Lean, then Cairn's bin/cairn-link
# merging the app's library with Lean's runtime and Cairn into .cairn/lib/libcairn_examples_<app>.a,
# then SwiftPM's host, one executable per app, each linking its own. Cairn comes from the registry (lean/lakefile.lean
# and Package.swift); Lake checks it out in lean/.lake/packages/cairn.

export PATH := $(HOME)/.elan/bin:$(PATH)
# Lake reads the registry as if it were Reservoir (Cairn's docs/cli.md, "Lake and the registry").
export RESERVOIR_API_URL := https://cairn.registry.nexthub.sh/api/v1
# The ledger, the audit and the doc tests import modules from the build directory, which Lake's
# artifact cache keeps them out of. `cairn` turns the cache on for its own commands.
export LAKE_ARTIFACT_CACHE := false

CAIRN_PKG = lean/.lake/packages/cairn
CAIRN = $(CURDIR)/$(CAIRN_PKG)/tools/cairn/.build/release/cairn
# Each app's Lean library. The executable is Cairn<App>.
APPS = Counter Basics Todo Clock Tray Gallery
# The apps with fuzz targets, as Cairn checks them (its FUZZ_APPS).
FUZZ_APPS = Counter Basics Todo Clock Tray Gallery
SIZE_LIMIT = 5000000

.PHONY: deps lean build check lint ledger ledger-update audit doctest kernel selftest fuzz-quick fuzz size cairn-tool clean

deps:
	cd lean && lake env true

lean:
	cd lean && lake build

build: cairn-tool
	@for a in $(APPS); do $(CAIRN) build --app $$a || exit 1; done

# Everything a PR must pass.
check: lint ledger audit doctest kernel selftest fuzz-quick size

# Constructs that bypass the kernel or swap in unchecked code (Cairn's AGENTS.md, "Writing Lean").
lint:
	@! grep -rnE 'implemented_by|skipKernelTC|native_decide|bv_decide|^\s*axiom ' lean --include='*.lean' --exclude-dir=.lake \
	  || (echo "lint: forbidden construct (AGENTS.md, Rules)"; exit 1)

# The claim ids, scope `cairn_examples`: every id in claims.lock is still issued (or retired),
# none is reused, and every claim in the code is locked (Cairn's docs/claims.md).
ledger: lean
	cd lean && lake exe ledger check --scope cairn_examples --root CairnExamples --lock ../claims.lock

ledger-update: lean
	cd lean && lake exe ledger update --scope cairn_examples --root CairnExamples --lock ../claims.lock

# Every theorem depends on propext, Classical.choice and Quot.sound at most.
audit: lean
	cd lean && lake exe audit CairnExamples

# Every Lean code block in a doc comment elaborates (Cairn's docs/doc.md, "Doc tests").
doctest: lean
	cd lean && lake exe doc --check CairnExamples > /dev/null

# Replay every declaration through the kernel (macOS: unsandboxed).
kernel: lean
	cd lean && lake check --inadvisably-no-sandbox

# Drives each app headlessly through the host's real threads, timers and accessibility mirror.
selftest: build
	@for a in $(APPS); do echo "== Cairn$$a --selftest"; swift run -q Cairn$$a --selftest || exit 1; done

# The `cairn` CLI, from the Cairn checkout Lake fetched.
cairn-tool: deps
	swift build -c release -q --package-path $(CAIRN_PKG)/tools/cairn

# 200 sequences of 50 steps on each of FUZZ_APPS, into build/fuzz/quick/ (`cairn fuzz`).
fuzz-quick: cairn-tool
	$(CAIRN) fuzz $(FUZZ_APPS) --iterations 200 --out build/fuzz/quick

# `make fuzz [N=1000] [SEED=0]` writes build/fuzz/<App>.json for every fuzzable app.
fuzz: cairn-tool
	$(CAIRN) fuzz --iterations $(or $(N),1000) --seed $(or $(SEED),0)

# Binary size (Cairn's bench/size.md): each executable built for release with a link map,
# stripped and attributed, and checked against SIZE_LIMIT bytes, into build/size/<App>/.
size: cairn-tool
	@for a in $(APPS); do $(CAIRN) size --app $$a --product Cairn$$a --limit $(SIZE_LIMIT) || exit 1; done

clean:
	rm -rf build .cairn .build lean/.lake
