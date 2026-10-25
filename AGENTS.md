# AGENTS

`cairn_examples`: Cairn's example apps (Counter, Basics, Todo, Clock, Tray, Gallery) as one
Cairn package that requires `cairn` from the registry (https://cairn.registry.nexthub.sh). Claim
scope `cairn_examples`: Counter's `^1` is `cairn_examples^1`. Read README.md for the layout.

## Rules

Cairn's rules apply (cairn's AGENTS.md, "Rules" and "Writing Lean"):

- **No `sorry`, no new axioms.** `make check` audits every theorem's axioms; only `propext`,
  `Classical.choice` and `Quot.sound` are allowed.
- **Banned:** `implemented_by`, `debug.skipKernelTC`, `native_decide`, `bv_decide` and `axiom`.
  `make lint` greps for them.
- **Ids are the contract.** Never renumber, reuse or delete a claim id; retire it instead.
  `claims.lock` is written by tools (`make ledger-update`), never by hand.
- **No `import Lean` in anything the host links.**
- **Toolchain** = Cairn's (`lean/lean-toolchain`). Bump it with Cairn's.

## Toolchain

`export PATH=$HOME/.elan/bin:$PATH` if `lake` is missing. Lake resolves
`require "iamnbutler" / "cairn"` through the registry, so `lake update` needs
`RESERVOIR_API_URL=https://cairn.registry.nexthub.sh/api/v1` (the Makefile sets it).

## Workflow: lane

Every change happens in a lane, never in the main checkout and never with a bare
`git worktree add`.

1. `lane new <name>` from an up-to-date main, then work in the printed tree.
2. `lane why <path>` before editing a file.
3. Commit as you go. Add a `Why: <path> | <note>` trailer only for a non-obvious constraint.
4. `lane check`; confirm, replace or retire stale notes.
5. `make check` passes.
6. `lane push`, then `gh pr create`. Check `git log --oneline -2` after pushing: the lane must sit
   on current `origin/main`.
7. Squash-merge (`gh pr merge --squash`, no `--delete-branch`), `git pull --ff-only` in the main
   checkout, `lane prune --dry-run`, then `lane rm <name>` for merged lanes prune misses. Never a
   bare `lane prune` while other agents may have lanes open.

<!-- lane:protocol -->
## Context memory

- Before editing a file, read `.lane/memory/<path>/` if it exists, or run `lane why <path>`.
- Record non-obvious findings with `lane note add <path> -a <anchor> "..."`.
- Do not edit `.lane/` by hand; landing manages it.
- Land with `lane merge`, or `lane push` where trunk is protected, then `lane prune` once it merges.
- Detailed workflow lives in `.agents/skills/lane/SKILL.md`; run `lane install skill` if it is absent.
<!-- /lane:protocol -->
