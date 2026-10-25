# Cairn's example apps. Lean builds each app; Cairn's bin/cairn-link merges one app's library with
# Lean's runtime and Cairn into .cairn/lib/libcairn_examples_<app>.a; SwiftPM builds the hosts,
# one executable per app, each linking its own. Cairn comes from the registry (lean/lakefile.lean
# and Package.swift); Lake checks it out in lean/.lake/packages/cairn.

export PATH := $(HOME)/.elan/bin:$(PATH)
# Lake reads the registry as if it were Reservoir (Cairn's docs/cli.md, "Lake and the registry").
export RESERVOIR_API_URL := https://cairn.registry.nexthub.sh/api/v1
# The ledger, the audit and the doc tests import modules from the build directory, which Lake's
# artifact cache keeps them out of. `cairn` turns the cache on for its own commands.
export LAKE_ARTIFACT_CACHE := false

CAIRN_PKG = lean/.lake/packages/cairn
CAIRN = $(CURDIR)/$(CAIRN_PKG)/tools/cairn/.build/release/cairn
LIBDIR = .cairn/lib

# Each app: its Lean library : its archive's suffix. The executable is Cairn<App>.
APPS = Counter:counter Basics:basics Todo:todo Clock:clock Tray:tray Gallery:gallery
PRODUCTS = $(foreach a,$(APPS),Cairn$(firstword $(subst :, ,$(a))))
# The apps with fuzz targets, as Cairn checked them (its FUZZ_APPS).
FUZZ_APPS = Counter Basics Todo
SIZE_LIMIT = 5000000

.PHONY: lean build check lint ledger ledger-update audit doctest kernel selftest fuzz-quick fuzz size cairn-tool clean

lean:
	cd lean && lake build
	@mkdir -p $(LIBDIR)
	@for a in $(APPS); do \
		(cd lean && ../$(CAIRN_PKG)/bin/cairn-link --lib $${a%%:*} --out ../$(LIBDIR)/libcairn_examples_$${a##*:}.a) || exit 1; done

build: lean
	swift build

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
	@for p in $(PRODUCTS); do echo "== $$p --selftest"; swift run -q $$p --selftest || exit 1; done

# The `cairn` CLI, from the Cairn checkout Lake fetched.
cairn-tool: lean
	swift build -c release -q --package-path $(CAIRN_PKG)/tools/cairn

# 200 sequences of 50 steps on each of FUZZ_APPS, into build/fuzz/quick/ (`cairn fuzz`).
fuzz-quick: cairn-tool
	$(CAIRN) fuzz $(FUZZ_APPS) --iterations 200 --out build/fuzz/quick

# `make fuzz [N=1000] [SEED=0]` writes build/fuzz/<App>.json for every fuzzable app.
fuzz: cairn-tool
	$(CAIRN) fuzz --iterations $(or $(N),1000) --seed $(or $(SEED),0)

# Binary size (Cairn's bench/size.md): each executable built for release with a link map,
# stripped and attributed, and checked against SIZE_LIMIT bytes, into build/size/<App>/.
# `cairn size` links every app in cairn.toml's `libs` into one archive, which can't hold six
# apps (cairn#SIZE_ISSUE), so this runs Cairn's tools/size/size.ts per app, as `cairn size` does.
size: lean
	@mkdir -p build/size
	@for a in $(APPS); do p=Cairn$${a%%:*}; \
		swift build -c release -q --product $$p -Xlinker -map -Xlinker $(CURDIR)/build/size/$$p.map || exit 1; done
	@for a in $(APPS); do p=Cairn$${a%%:*}; \
		bun $(CAIRN_PKG)/tools/size/size.ts --bin $$(swift build -c release --show-bin-path) --maps build/size \
		  --out build/size/$${a%%:*} --limit $(SIZE_LIMIT) --lib libcairn_examples_$${a##*:}.a --modules $${a%%:*} \
		  --swift $(CURDIR) $$p || exit 1; done

clean:
	rm -rf build .cairn .build lean/.lake
