# cairn_examples

Cairn's example apps, as one package that requires [Cairn](https://github.com/iamnbutler/cairn) from
the registry (https://cairn.registry.nexthub.sh). Each app's behaviour is a set of claims with
durable ids and machine-checked evidence.

| App | Lean | Host | Claims |
|---|---|---|---|
| Counter | `lean/Counter.lean` | `CairnCounter` | ^1–^6 |
| Basics | `lean/Basics.lean` | `CairnBasics` | ^101–^109 |
| TodoMVC | `lean/Todo.lean`, `lean/Todo/` | `CairnTodo` | ^201–^225 |
| Clock | `lean/Clock.lean` | `CairnClock` | ^401–^409 |
| Tray | `lean/Tray.lean` | `CairnTray` | ^450–^462 |
| Gallery | `lean/Gallery.lean` | `CairnGallery` | ^501–^513 |

They were copied from Cairn's `lean/Examples` and `host/Sources/Cairn<App>` at 885b585 (Cairn
0.2.2), as step 3 of cairn#137. The claim scope is `cairn_examples`, and every claim kept its number:
Cairn's `cairn^201` is `cairn_examples^201` here. Two of the examples' old claims stay in Cairn.
They are host assumptions that every app relies on, so they belong to Cairn's trusted base:
`cairn^7` (the host reports clicks where they happen) and `cairn^214` (the host reports a double
click as a second click). Claims can't cite another scope yet (cairn#85), so the code names them
only in comments.

## Layout

```
cairn.toml          the package: name, version, kind = "bin", the six app libraries
claims.lock         every cairn_examples^N ever issued (`make ledger-update` writes it)
lean/               the Lake package: one lean_lib per app (<App>.lean, <App>/), CairnExamples.lean
                    (every app with its proofs and tests), FuzzMain.lean (`cairn fuzz`)
host/Sources/       one SwiftPM executable per app (Cairn<App>), and CExamples (the apps'
                    Lean initializers)
Package.swift       the hosts; Cairn's Swift products from the registry
```

v1 apps all export `cairn_app_init/step/frame`, so each executable links exactly one app:
`make lean` runs Cairn's `bin/cairn-link --lib <App>` once per app, into
`.cairn/lib/libcairn_examples_<app>.a`.

## Make

| Target | What it does |
|---|---|
| `make build` | `lake build`, the six archives, `swift build` |
| `make check` | everything a PR must pass: `lint`, `ledger`, `audit`, `doctest`, `kernel`, `selftest`, `fuzz-quick`, `size` |
| `make selftest` | each app's `--selftest`, headless, through the host's real threads and accessibility mirror |
| `make fuzz-quick` | `cairn fuzz Counter Basics Todo`, 200 sequences each, into build/fuzz/quick/ |
| `make size` | each executable's release size, attributed, against 5,000,000 bytes, into build/size/<App>/ |
| `make ledger-update` | rewrite claims.lock after adding or retiring a claim |

`swift run CairnTodo` opens an app.

`cairn build`, `cairn size`, `cairn bench` and `cairn conformance` link every library in
cairn.toml's `libs` into one archive, so they don't work on a package with six apps yet
(cairn#173). `make size` runs Cairn's `tools/size/size.ts` per app instead.
