import Lake
open Lake DSL

/-- Cairn's example apps (../README.md). The package name is the claim scope: Counter's claims are
`cairn_examples^1`, in ../claims.lock. -/
package cairn_examples where
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩,
    -- `weak.`: Lake passes it to every module, and only those that use the claim commands know it.
    ⟨`weak.cairn.claims.scope, "cairn_examples"⟩]

require "iamnbutler" / "cairn" @ "^0.2.3"

/-- Every app with its proofs and tests (`CairnExamples.lean`): what the ledger, the axiom audit
and the kernel replay read. Never linked. -/
@[default_target]
lean_lib CairnExamples

/-! One library per app, and each host executable links exactly one (`make lean`, Package.swift):
v1 apps all export `cairn_app_init/step/frame`, so two in one binary would clash. `cairn-link
--lib <App>` merges an app's library with Lean's runtime and Cairn into
.cairn/lib/libcairn_examples_<app>.a. The host calls the app module's `runtime_initialize_*`. -/

/-- Counter: its exports (`Counter.Abi`) and the app. The exports are a separate module so that
executables importing every app (the fuzzer) don't get two `cairn_app_init`s. -/
@[default_target]
lean_lib Counter where
  roots := #[`Counter.Abi, `Counter]
  defaultFacets := #[LeanLib.staticFacet]

/-- Basics: the app and its exports, in one module. -/
@[default_target]
lean_lib Basics where
  roots := #[`Basics]
  defaultFacets := #[LeanLib.staticFacet]

/-- TodoMVC: its exports (`Todo.Abi`), the app, model and view. -/
@[default_target]
lean_lib Todo where
  roots := #[`Todo.Abi, `Todo, `Todo.Model, `Todo.View]
  defaultFacets := #[LeanLib.staticFacet]

/-- Clock: a stopwatch on time, timers and file requests (`Clock.Abi`, the exports). -/
@[default_target]
lean_lib Clock where
  roots := #[`Clock.Abi, `Clock]
  defaultFacets := #[LeanLib.staticFacet]

/-- Tray: a menu bar item and an overlay panel (`Tray.Abi`, the exports). -/
@[default_target]
lean_lib Tray where
  roots := #[`Tray.Abi, `Tray]
  defaultFacets := #[LeanLib.staticFacet]

/-- Gallery: image tiles loaded with `loadImage` (`Gallery.Abi`, the exports). -/
@[default_target]
lean_lib Gallery where
  roots := #[`Gallery.Abi, `Gallery]
  defaultFacets := #[LeanLib.staticFacet]

/-- `cairn conformance`'s generator entry points (Cairn's docs/conformance.md), one per app that
has one. Declared after the apps, whose roots would otherwise claim them. Never linked. -/
@[default_target]
lean_lib AppConformance where
  roots := #[`Counter.Conformance, `Basics.Conformance, `Todo.Conformance, `Tray.Conformance]

/-- `cairn fuzz`: Cairn's claim-driven fuzzer on every app (Cairn's docs/fuzz.md). -/
lean_exe fuzz where
  root := `FuzzMain
