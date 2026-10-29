# The default workflow: reference

Everything the `default` workflow does, step by step, and every setting it
reads. The engine it runs on — `gtd.config.ts`'s shape, steps, landing, replay,
doors, the `config` export — is documented in gtd's
[configuration reference](https://github.com/pmelab/gtd/blob/main/docs/configuration.md);
this page links there as **gtd's configuration**. For the walkthrough of what a
person does, read [the guide](./default.md) first.

Examples import the workflow from its pinned bundle, as the config
`gtd-wf config default` prints does. They write that absolute path as
`/home/me/.local/share/gtd/workflows/dist/default.mjs`; use your own.

## Using it in `gtd.config.ts`

The bundle exports the workflow's factories, its parts and the reserved exports
(`defaults`, `envDefaults`, `summary`, `base`, `steering`, `skills`, `access`).
The startable workflows are [factories](#factory-options) (`feature`, `review`,
`fix`, `rollout`, `cleanup`) and plain flows (`ordinaryStart`, `reviewFlow`,
`fixFlow`, …); the phases (`unwind`, `planAndBuild`, `design`, `buildFeature`,
`seamBuild`, `implement`, `refactorFirst`, `buildTail`, `handOffTail`,
`handOffReview`, `fixReviewNotes`, `qualityLap`, `healthy`, `gate`, …) and every
single step (`triage`, `naivePass`, `fixCheck`, `reviewing`, `collecting`, …)
are named exports too. A step's name is relative to the `scope()` it runs in —
the workflow's `scope("build", …)` around `healthy` is what makes
`build.health.check`. The full step names are this workflow's public API: a
rename strands every process resting on the old name, so it only happens in a
breaking release of this repository.

Re-export `envDefaults` alongside `defaults`: a workflow that re-exports only
`defaults` loses `testCommand`, `plannerModel` and `coderModel`. Re-export
`skills` alongside `steering`: it is what makes the workflow's scope names
addressable by a `config.skills` entry in THIS config (see
[Skills and access](#skills-and-access)) — dropping it from the re-export list,
the way dropping any other named export does, silently empties it instead of
keeping the workflow's defaults, because gtd reads a missing export as `{}`.

**Import the phases; never `export *` them.** Every exported function of your
file is a startable workflow, so `export *` from the bundle would turn each
phase and step into one — `gtd --workflow buildTail` would start a half-flow and
strand the process. Re-export the reserved names and the workflows you want
startable by name, and write each other workflow you want as your own function:

```ts
import { start } from "@pmelab/gtd/flows"
import {
  afterTail,
  buildTail,
  feature,
} from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export {
  defaults,
  envDefaults,
  summary,
  steering,
  skills,
} from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export default feature

export async function hotfix() {
  return afterTail(await buildTail(start(), { fixFirst: true }))
}

export const doors = { hotfix: { workflow: "hotfix" } }
```

`buildTail(base, options?)` is the call form;
`buildTail(fixFirst, base, green?, options?)` is deprecated. A string second
argument selects the deprecated form, which then needs `fixFirst` and `green`
booleans or absent and `options` an object or absent; otherwise a string first
argument selects the current form, which takes nothing but an optional `options`
object. `null` counts as absent. A call fitting neither form is rejected before
any of `buildTail`'s own steps run. Every `BuildTailOptions` field accepts an
explicit `undefined` as absent, and its `feedback` and `lap` types are exported
as `FeedbackTarget` and `ReviewRange`.

`tail(finish, options?)` is the build tail without the review: its quality lap
is [triaged](#the-triaged-quality-lap), `.gtd/QUALITY.md` is removed, and
`finish` runs last with the escalation count and the lap's report (`LensReport`:
`notes`, `fixed`, `noise`) for it to show or pass on; `options` (`TailOptions`)
takes `fixFirst`, `green`, `guard`, `lenses`, `guardRests`, `lensBase` and
`rules`. `lenses` entries take the `qualityReviews` form, `<lens>` or
`<lens>=<model>` (`lensEntriesOf` splits a list into them, `lensOf` splits one,
`lensesOf` keeps only the names); passed in, they replace `qualityReviews` hints
and all.
`tail(fixFirst, finish, green?, guard?, lenses?, guardRests?, lensBase?, rules?)`
is deprecated; a function second argument selects it. A call fitting neither
form is rejected before any step runs.

A config's doors are those its workflows bring plus its `doors` export: export
`fix` and `review` to keep their doors, `rollout` and `cleanup` to add theirs
(see gtd's configuration,
[Doors](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#doors)).
The bundle's own `doors` export is an empty no-op, and its `base` export maps
`reviewBase` for a workflow named `review`; both are kept only so an older
config re-exporting them still loads.

### Factory options

`feature`, `review`, `fix`, `rollout` and `cleanup` are
[workflow factories](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#workflow-factories):
calling one with options returns that workflow configured. Their options are the
[settings](#settings), each a string (`naiveTest` a boolean, stored as
`true`/`false`), and each becomes that workflow's own default of its kind —
beneath `--var` and `GTD_<NAME>`, which still layer on top:

```ts
import {
  feature,
  review,
} from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export {
  summary,
  steering,
  skills,
  access,
} from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export default feature({ testCommand: "npm run test:ci", coderModel: "fast" })
export const quickReview = review({ qualityReviews: "correctness" })
```

Exported without a call, a factory is a workflow too, with its default options.
Either way gtd **validates the options when it loads the config**. A rejected
option fails every command:

```text
gtd config:
  - /repo/gtd.config.ts: testComand: workflow "default" option "testComand": is unexpected, expected: "reviewBase" | … | "coderModel"
```

Unknown options are rejected, not dropped, so a misspelled or removed option
fails the load.

Awaiting a factory's call inside a composed flow throws — compose `fixFlow`,
`reviewFlow` and the other plain flows instead.

## The workflows

The bundle offers five startable workflows; `gtd-wf config default` exports the
first three.

- **`feature`** — the ordinary start, and its `default`: plan, build, the
  quality lap, then a human review whose notes are triaged and, for an edit,
  re-planned.
- **`review`** — `feature`'s review of everything since
  `--var reviewBase=<commitish>`, with no design phase: a green gate
  (`review-gate`), the triaged quality lap, then the human review of
  [The feature review](#the-feature-review). Fixes and nits are fixed in place
  (`build.review.fix.nits.fixing`); a note judged `edit`, or a hand-edit, is
  collected into `.gtd/REQUIREMENTS.md` (`build.review.collecting`), your edits
  are reverted (`re-unwind`), one turn builds it (`feedback.fixing`), the file
  is removed (`feedback.closing`), and the tail runs again. A sign-off ends the
  process with no review file left. Starting it is refused while a pending
  hand-off from `fix` or a leftover `.gtd/REQUIREMENTS.md` is in the tree.
- **`fix`** — with a handed-off `.gtd/REVIEW.md` in the tree, one turn fixes
  every note (read from the two review files) and every `Risk:`
  (`notes.fixing`), both files are removed (`notes.closing`), and the result
  goes through the build tail to its own hand-off review. With none, it repairs
  a red baseline (`fix-precheck`) through the same tail. A note at its review
  ends the process with `.gtd/REVIEW.md` kept and the reviewer's own version
  copied beside it as `.gtd/REVIEW.orig.md` (`build.review.handing-off`), for
  the next `fix`, never re-planned. Until then, starting `feature` or `review`
  is refused; remove both review files to abandon the hand-off. `fix` refuses a
  lone `.gtd/REVIEW.orig.md`.
- **`rollout`** and **`cleanup`** — retire a release flag; see
  [Rolling out and cleaning up a release flag](#rolling-out-and-cleaning-up-a-release-flag).

**Upgrading:** the old state-named entry flag is gone, replaced by `--workflow`.
Finish or abandon any process started with it before upgrading — its opening
commit names no workflow, so it no longer replays.

## `refactorFirst`

`refactorFirst(shape, { reference? })` turns a `judgeDiffShape` result into a
behaviour-neutral refactor of its `strays`, minus any test file, and resolves
`true` once the refactor has closed. It resolves `false`, running no step,
unless `shape.choice` is `refactor-first`, `shape.unreadable` is empty and a
non-test stray remains — a stray whose content cannot be read goes to a human
instead, and a `refactor-first` whose strays are all test files goes straight to
`implement.*`, since a refactor never refactors a test file. `reference` is the
naive pass's kept tip (`kept(name)?.hash`; blank counts as none): the building
prompt names `git show <reference> -- <strays>` as reading material only and
forbids applying it, and names that diff's changes to existing code as the seam
the refactor must land — a refactor touching none of it is wrong; omitted, it
carries no reference line. `note` is the refactor note's text (blank counts as
none): the package carries it under `## Refactor note`, headings demoted, and
the building prompt tells the turn to build exactly the seams it names.

`refactorFirst` is the refactor alone. The `feature` flow runs
`reviewedRefactor`, which is `refactorFirst` plus the refactor's quality lap and
review inside the same `refactor` scope, so the tail's steps are
`refactor.build.*`; it resolves `true` on sign-off and `false`, running no step,
on exactly the shapes `refactorFirst` rejects. The review tail's fix-check,
quality-fix, risk-fix, nit-fix and describe turns (`refactor.build.*`) are
guarded and prompted with the same rules as the refactor's own turns below.

The refactor review's closed collecting turn (after the review file is closed)
folds into `.gtd/REFACTOR.md` what that round left: every hand-edit and every
note after a hand-edit round, each note that asks for a change after a notes
round, each `edit`-judged note after a triaged round. It carries no
reply-in-place rules; those belong to the in-gate reply turn.

It runs inside the scope `refactor`, whose write access is the strays, the test
files (the list below) and `.gtd/**`, in these steps: `refactor.deriving`
(writes `.gtd/REFACTOR.md`, a file a person can read and edit),
`refactor.building`, the shared health loop (`refactor.health.check`,
`refactor.health.judge`, `refactor.health.recheck`, `refactor.health.describe`,
`refactor.health.stop`, `refactor.health.exhausted`) with
`refactor.fix.suite.fixing`, and `refactor.closing`, which removes only the
package file. A red suite goes to the fix loop, never to a refusal.

The package file's `## Scope (read-only)` list is for reading: the guards use
the strays as fixed when the package was derived, so editing the list widens or
narrows nothing. After the building turn, after every fix turn and after the
escalation describe turn (`refactor.health.describe`), `gtd land` refuses the
turn when:

- it changed a test file in any way but updating its call sites
  (`refactor-tests`). A test file is any path matching `**/*.test.*`,
  `**/*.spec.*`, `**/*.feature`, `**/tests/**`, `**/test/**` or
  `**/__tests__/**`; the list is fixed — `seamAllow` does not narrow it — and
  `*_test.go`, `test_*.py` and other namings are not test files here, so their
  call sites stay out of reach. An existing test file may be modified, so a seam
  that changes a call shape can update its callers there. Refused: adding or
  deleting a test file; changing a `.snap` snapshot or a `.feature` file (call
  sites live in code); changing a test file whose before or after cannot be
  read, or that held no `expect`/`assert*` call and no `it`/`test`/`describe`
  block (test data or a helper); and changing, outside comments, a file's count
  of `expect`/`assert*` calls, of `it`/`test`/`describe` blocks, or of skipped,
  focused or todo ones (`.skip`, `.only`, `.todo`, `xit`, …). A changed expected
  value keeps every count: the refactor review's prompt asks the reviewer to
  flag it, and `refactorFirst` alone has no review. Or
- it changed a path outside `.gtd/` that is neither a modified test file nor
  exactly one of the strays (`refactor-scope`; a fix turn is judged on its own
  changes, so a person's edit at an escalation stop does not block it; no globs:
  a stray `src/*.ts` does not admit `src/a.ts`), or
- it raised the number of reads of any one flag, or added a flag, across the
  changed files outside `.gtd/`. A flag is a match of the `refactorFlagPattern`
  setting; moving a read passes, and so does a swap that leaves every per-name
  count flat. A changed file whose before or after cannot be read refuses.

The human rests `refactor.health.stop` and `refactor.health.exhausted`, and
their counterparts in the refactor's review tail (`refactor.build.health.*`),
are never guarded: a person's edit there is not refused. The flag count, though,
spans every turn since the build: a flag read a person adds there refuses the
next fix turn until it is removed, and that turn may not touch the file to
remove it. Put no flag read in a person's edit at these rests.

A blank or invalid `refactorFlagPattern` throws before the first step, naming
the setting. A pattern that produces a zero-length match (a lookahead-only
pattern such as `(?=GTD_FLAG_\w+)`) on a stray throws before the first step, and
on text a turn introduces refuses the landing, naming the setting. The `feature`
flow runs `reviewedRefactor` on the [naive-pass path](#the-naive-pass-path);
call `refactorFirst` or `reviewedRefactor` from your own workflow after
`judgeDiffShape`, with a suite that is already green: the fix turns may touch
only the strays, so they cannot repair a failure outside them.

## Acceptance criteria

`.gtd/REQUIREMENTS.md` lists the change's acceptance criteria under a level-2
`## Acceptance Criteria`, one `- AC-<n>: <criterion>` line each, up to the next
heading. They are the build's stop condition, so each must be behaviour a test
can pin. A green suite, typecheck, lint or build is not a criterion: the health
check already enforces it. Every later step re-reads them from the file.

- **Full path.** `design.triage` writes them; `gtd land` refuses a triage turn
  whose file has no criteria, a criterion without an ID, or two criteria sharing
  one (`acceptance-criteria`). While the file holds them, a later lap is asked
  to keep their IDs: reword in place, append with the next unused number, never
  renumber. The design gate settles them. Triage also writes a `## Impact`
  section — the units and public surfaces the change touches — which you may
  correct at the design gate like any other prose; the next lap re-explores from
  your edit. `gtd land` refuses a triage turn that leaves no `## Impact`
  (`impact`).
- **Skip path.** When the sketch adds or changes a list under an
  `Acceptance criteria` heading (any level, trailing `:` allowed) in exactly one
  `TODO.md` (any directory) and changes nothing else, `design.clear` asks a
  judge whether every criterion is clear and checkable. `yes` at `p` ≥ 0.8, with
  no evidence truncated, runs `design.normalise`: a script writes the list to
  `.gtd/REQUIREMENTS.md` as `AC-1`, `AC-2`, … (or keeps the sketch's own
  `AC-<n>` IDs when every item has a distinct one), with a `git show` pointer to
  the sketch, then a `design.impact` agent turn adds a `## Impact` section, and
  a [`## Release Flag`](#release-flags) section when the sketch asks for a flag
  — refused when it adds no Impact (`impact`) or changes anything else
  (`impact-only`) — and the process goes to `seam.naive`: no triage, no design
  gate, no human rest, and nobody reviews that Impact before the build. Anything
  else, including one vague criterion, falls back to `design.triage`. A sketch
  with no such list skips the judge. With `GTD_FLAG_RISK_TIER` on there is no
  skip path: the tier is proposed at triage and set at the design gate.
- **Frozen.** After design only another design lap (review feedback) changes
  them: `gtd land` refuses an `implement.building` or
  `implement.fix.suite.fixing` turn that edits them (`criteria-frozen`).
  `seam.steer` is a human gate and may, but its edit must leave ID'd criteria,
  as at triage.
- **Stable after review.** A review feedback lap's design keeps a built
  criterion's ID — reworded in place when the review changes that behaviour, or
  deleted when it drops it — and numbers new behaviour above every ID handed out
  so far, including one a person narrowed away. `gtd land` refuses a triage turn
  that lists any other ID at or below that number (`criteria-ids`). It reads IDs
  only: a built criterion reworded to mean something else keeps its ID
  unnoticed.

**Upgrading:** finish or `gtd abandon` before upgrading any process that has
landed a `design.triage` turn whose `.gtd/REQUIREMENTS.md` has no ID'd
acceptance criteria — replay re-checks that turn and refuses it — and any
process past `start-gate.check` whose sketch held an `Acceptance criteria` list
in a `TODO.md`. A process resting at `design.triage` keeps replaying; its next
turn needs ID'd criteria.

## Release flags

A change ships behind a release flag only when its requirements ask for one.
`.gtd/REQUIREMENTS.md` then carries a `## Release Flag` section whose first line
is:

- `new` — the change goes behind a new release flag, following the repository's
  flag conventions
- `existing: <NAME>` — the change goes behind a flag that already exists, named
  as the project names it (`existing: GTD_FLAG_BETA`); no new flag is added

`design.triage` writes the section only when the sketch asks outright for a
flag, and keeps it on every later lap; on the skip path `design.impact` writes
it. Add, change or delete it at the design gate yourself. No section (or `none`)
ships the change unflagged. A first line that is none of these refuses the
landing (`release-flag`), at design and wherever the flow reads it later.

With a flag asked for, the naive pass goes to the seam judge (`seam.judge`) and
may be refactored first (see [the naive-pass path](#the-naive-pass-path)); a
build turn is told to add the new flag, or to use the named one. Without one, no
seam judge or refactor runs: after `seam.naive` and `seam.check` the vetted pass
lands as the implementation (`implement.applying`, no build turn, no flag), then
the health loop, `implement.closing` and the quality lap. The section is read
when the step runs, so an edit at `seam.steer` or `seam.try` takes effect on the
next pass. `GTD_FLAG_RISK_TIER`'s tier no longer decides a flag.

**Upgrading:** `flagMode` is gone. A `feature({ flagMode })` option is refused
as unknown — drop it; `--var flagMode` and `GTD_FLAGMODE` are ignored. A project
that relied on the old default (flags on) now ships unflagged unless a sketch
asks: add `## Release Flag` to its requirements, or ask in the sketch. Finish or
`gtd abandon` any `feature` process past `design.gate.answer` (or past
`design.impact` on the skip path) before upgrading: its replay now decides the
seam judge from `.gtd/REQUIREMENTS.md`, not `flagMode`.

## The naive test

With [`naiveTest`](#settings) on (off by default), a person tries every green
naive pass by hand before anything builds on it — no seam judge, refactor,
implementation or quality lap runs first. `seam.applying` puts the kept pass,
outside `.gtd/`, in the working tree as a commit, and the process rests at
`seam.try`. Run it, click through it, use it.

- **Sign off** — land a clean tree. `seam.restoring` takes the pass out again
  and the process goes on: to `seam.judge` when a [release flag](#release-flags)
  is asked for, else straight to `implement.applying`.
- **Send it back** — write notes in `.gtd/NAIVE-TEST.md`, edit the code to show
  what you mean, or edit `.gtd/REQUIREMENTS.md` (its criteria must stay ID'd),
  then `gtd land`. `seam.restoring` takes the pass, your code edits and the
  notes file out of the tree again — an edit to `.gtd/REQUIREMENTS.md` stays —
  and `seam.naive` runs again: its prompt names the tried pass to pick up,
  quotes your notes and names your landing commit (`git show <commit>`) when it
  changed code. The new pass goes through `seam.check` and rests at `seam.try`
  again; a send-back refills the retry budget.

Nothing else tries the change by hand: the green suite, the quality lap and the
review are what check that a criterion is met.

**Upgrading:** the hands-on test is gone, and with it `prototypeRounds`, the
`implement.prototype.*` steps, `.gtd/PROTOTYPE.md` and the `(no hands-on)`
criterion tag (a criterion carrying it no longer reads as ID'd). Finish or
`gtd abandon` any `feature` process past `implement.health.check` (resting at
`implement.prototype.*`, `implement.closing` or later): replay now expects
`implement.closing` right after the health loop. A
`feature({ prototypeRounds })` option is refused as unknown — drop it. Custom
fixtures driving `feature` land `implement.health.check → implement.closing`.

## The naive-pass path

The `feature` workflow's path when the requirements ask for a
[release flag](#release-flags); without one, steps 1 and 2 run, no judge, and
the pass lands as on `land`. With [`naiveTest`](#the-naive-test) on, a person
tries every green pass between steps 2 and 3 (`seam.applying`, `seam.try`,
`seam.restoring`). After design it runs, in order:

1. `seam.naive` — an agent implements `.gtd/REQUIREMENTS.md` directly,
   breadth-first; the turn is a
   [kept tip](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#kept-tips),
   not landed on the branch until a `land` applies it. It is asked for one test
   per behaviour the criteria describe, never a criterion ID in a test name, but
   needs no test at all. A pass whose added or changed test files (the fixed
   list `**/*.test.*`, `**/*.spec.*`, `**/*.feature`, `**/tests/**`,
   `**/test/**`, `**/__tests__/**`) import a non-test file the pass added
   (`acceptance-internals`: the string a `from`, `import`, `require(` or `mock(`
   takes, outside comments; relative ones resolved from the test's directory,
   `@/`-, `~/`- or `#`-aliased ones matching the path's end, others only as the
   exact path; a computed import goes unseen, and `.feature` and `.snap` files
   are not read for imports) runs `seam.naive` again, told why and to pick the
   attempt up.
2. `seam.check` — runs [`testCommand`](#settings) with the kept pass applied to
   the tree, then puts the pass's paths, and every other path the run changed or
   added that was not already dirty or untracked, back as `HEAD` has them (the
   pass's paths before the run too, so an interrupted one is cleaned up). Red —
   or a pass that no longer applies — writes `.gtd/FEEDBACK.md` and runs
   `seam.naive` again, told to pick the last attempt up and fix it; green goes
   on.
3. `seam.judge` — a judge rules on the shape of that diff (see
   [Judges](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#judges)):
   `land`, `refactor-first` or `reject`.
4. `land` — or an overrule of `reject` at `seam.steer` — applies the kept pass
   as the implementation: `implement.applying` puts its diff, outside `.gtd/`,
   in the tree, with no build turn and no release flag, and the health loop
   follows. A pass that no longer applies writes `.gtd/FEEDBACK.md` and falls
   back to `implement.building`, built fresh from it as below; so does one with
   nothing outside `.gtd/` to apply. `refactor-first` never applies the pass:
   first `seam.note`, an agent turn, reads the whole naive diff and writes
   `.gtd/REFACTOR-NOTE.md` — which seams the refactor opens and the shape each
   takes. A note turn that changes any other path, or leaves the note empty, is
   refused (`refactor-note`). Then the refactor and its review run, flag-free
   and behaviour-neutral, landing on their own with the existing suite green:
   `refactor.*` (its package carries the note under `## Refactor note`), then
   the refactor's quality lap (`refactor.build.quality.<lens>`, one per
   [`refactorQualityReviews`](#settings) lens) and a human review
   (`refactor.build.review.*`). The review's sign-off is the approval; no
   `Gtd-Approved:` trailer is recorded. Strays whose content cannot be read rest
   at `seam.by-hand`, with no refactor; a clean `gtd land` continues. `reject`
   discards the pass and runs `seam.naive` again. Rejects, test faults and red
   checks share one budget: two retries, then `seam.steer`.
5. `implement.*` — after a refactor (or a pass that no longer applies), one
   build turn that reads the kept pass as material only; after `land`, the
   applied pass. After a `refactor-first` verdict the build turn is the rebuild:
   its prompt quotes the refactor note (after a refactor; the note is fixed when
   `seam.note` lands, so a later edit of the file reaches neither turn) and
   names every test file the naive pass added or changed
   (`git show <tip> -- <tests>`) to carry over. Nothing refuses a rebuild or a
   fix turn that drops one: a criterion left untested surfaces as a
   `criteria-coverage` finding in the quality lap. Then the health loop
   (`implement.health.*`, `implement.fix.suite.fixing`) and `implement.closing`,
   which removes `.gtd/REQUIREMENTS.md` (and `.gtd/REFACTOR-NOTE.md`, when there
   is one). A build turn is asked for a new release flag. The feature's quality
   lap (`build.quality.<lens>`) follows, then the
   [feature review](#the-feature-review) (`build.review.*`); its findings are
   [triaged](#the-triaged-quality-lap). After a refactor the build turn may
   change nothing but the carried-over tests — the refactor already carried the
   whole feature — and an empty turn completes the step when the naive pass's
   tests named no ID.

The refactor's quality lap reviews from its entry commit, the feature's from the
refactor's sign-off (from the process start without a refactor). The one
exception is a feature that changed no code but tests (step 5): its quality lap
covers the whole change from the process start, refactor included.

## The triaged quality lap

Every quality lap is triaged — ahead of every `feature` review (the feature's
and the refactor's), in the `review` door, and in `fix` and `cleanup` — and the
quality lenses are the only agentic review. Each lens appends its findings to
`.gtd/QUALITY.md`, one `## <title>` chunk per finding (prose outside every chunk
counts as one more finding). A judge, `build.quality.triage`, classifies each
one (`Q1`, `Q2`, … in file order):

- `mechanical` — fixed by `build.fix.quality.fixing`, up to three turns, each
  deleting the chunks it resolved; the health loop then runs the suite green
- `noise` — set aside, recorded on the judge's landing as
  `Gtd-Mark: noise=<id> p=<p> <title>`
- `design` — it questions a criterion or the approach: a note

A verdict below `qualityTriageMinP` (`0.7`), a missing one, or a finding the
judge's budget cut is `design`. `build.quality.sorting` leaves only the
mechanical findings in `.gtd/QUALITY.md` for the fix turns; mechanical findings
still there after the third turn become notes too (marked unresolved, or, when a
turn renamed another chunk, unclear) — never an escalation.

## The finding gate

With any note or noise left, `build.quality.gating` rewrites `.gtd/QUALITY.md`
in the `findings` mode and the process rests at the human gate
`build.quality.gate`: the notes as `## <title>` entries, then the noise under
`# Dropped as noise`, each naming its lens, its status and the judge's `p`, and
each ending in one `- [ ] fix` box. Tick a box to have that finding fixed, and
optionally write guidance on the lines below it; leave it unticked to drop it.
Landing the file untouched (or deleting it) drops every finding. The landing is
refused (`finding-gate`) while an entry holds no box, more than one, or guidance
under an unticked box. `gtd check findings <file>` runs the same check. A lap
with no notes and no noise has no gate.

The ticked findings are fixed, never re-planned: `build.quality.picking`
rewrites `.gtd/QUALITY.md` to just those, each with your guidance, the same fix
turns run (up to three), and the health loop runs the suite green. There is no
second lap and no second gate: what the turns leave is reported unresolved.
`build.quality.closing` then removes whatever is left of `.gtd/QUALITY.md`.

## The final review

Every final review — `feature`'s and the refactor's, the `review` door's, and
the hand-off review of `fix` and `cleanup` — is a reviewer turn
(`build.review.reviewing`, `refactor.build.review.reviewing`) walking the human
through everything since the review base: `## ` chunks grouped by concern, each
with at least one pointer to its code (`./path#start-end`), a `Weakened:` note
on each scenario that lost a `Then` line. A chunk with no pointer (in a range
that changed code), a `## Standard conflict` chunk the reviewer wrote itself,
two chunks sharing a title, or a `## Findings` or `## Walkthrough` heading
refuses the turn (`review-pointers`). gtd then appends (`build.review.carrying`)
any open standard conflicts, one `## Quality lap` chunk — what was fixed
automatically and fixed at the finding gate (each with its fixing commit),
dropped at the finding gate, dropped as noise, and unresolved after the finding
gate — and `## Standards added`. None of it takes an answer: to reopen a
finding, write a note under its line, judged like any other note. A pointer note
the reviewer opens with `Risk:` is fixed by `build.review.fix.risks.fixing`
straight after the reviewer turn, the suite is kept green, and the reviewer
writes the review once more over its own draft; only that review gets gtd's
chunks. After a nit fix the reviewer is told the fixing commit; after a round
that also answered a question, it carries those answers over. The refactor's
reviewer covers the whole refactor since it started on every round, gives any
test-file hunk a chunk of its own, and says so when it changes a test, an
assertion or an expected value.

A chunk added with its own `Tick exactly one:` boxes — as `/gtd pr` imports a
pull request thread — is answered by its tick: `fix as suggested` joins the nit
batch (`build.review.fix.nits.fixing`) with the chunk's text; `won't fix` drops
it and records `Gtd-Mark: wontfix=<title>` on the gate's commit; an own answer
over `_your answer_` is judged like any other note, keyed `answer-<n>`. The
review gate refuses to land (`answer-completeness`) until each such chunk holds
exactly one tick. Nothing is written to `.gtd/TODO.md`.

## Learned standards

`feature`'s review and the `review` door learn alike, from the answers to chunks
that carry their own boxes. Once a review round's answers are recorded, and
before any is routed, each won't-fix and each own answer becomes a candidate
standard — `Won't fix:
<title> — <the note's first paragraph>`, or `<your answer> (re: <title>)` —
unless `.gtd/STANDARDS.md` already holds it. `build.review.standards.judge`
asks one yes/no per candidate (`standard-<n>`: is it reusable beyond this
note?), and whether it contradicts each kept standard
(`standard-<n>.contradicts-<k>`) and each candidate before it
(`standard-<n>.contradicts-new-<m>`). Each kept standard is its own evidence
key. A candidate is kept only on a `yes` at `standardMinP` or above, its
evidence and every kept standard's uncut; landing the judge without a verdict
keeps none, and a blank `standardMinP` asks no judge at all. A kept candidate
any contradiction question does not rule out — a `no` at `standardMinP` — is
not applied: it is written under `## Undecided`, each contradicted standard as
a nested `- contradicts:` line. `build.review.standards.recording` writes the
file, and `build.review.standards.raising` appends one
`## Standard conflict <id>` chunk per new conflict to `.gtd/REVIEW.md`, its
boxes `keep the new one (drop the old)`, `keep the old one (discard the new)`
and `_your answer_` — read by position, like a note's. The answer is settled
there and never routed: the new standard replaces the old ones, is dropped, or
your text replaces both. A sign-off while `## Undecided` holds anything composes
the review again with those conflicts instead, so the process never ends with
one open. A fresh review lists every standard kept since its base under
`## Standards added`.

Every agent turn the workflows open with their skills preamble — the lenses,
naive pass, build, every fix, collecting and answering turns — gets the kept
standards (never the undecided ones) appended to its prompt; `seam.note` and the
`rollout`/`cleanup` turns do not. Any top-level bullet is a standard, numbered
or not, grouped under any heading but `## Undecided`; gtd rewrites the file as
one list when it learns, dropping prose and duplicates. Standards compare
without emphasis marks or case, so a formatter's rewrite never makes a standard
new. A kept standard the judge's evidence budget cuts leaves that round
unlearned — raise `judgeBudgetBytes` once the file grows long. Answering a
conflict drops the standards it replaces from every other open conflict, which
then asks only whether to keep, discard or reword its new standard.

## The feature review

After the quality lap, the process rests at the human review (`build.review.*`,
`.gtd/REVIEW.md`) over the whole change from the process start — on
`refactor-first`, everything since the refactor's sign-off, unless the refactor
carried the whole feature (step 5), when it re-covers the refactor too. A
sign-off ends the process at `idle`. Notes are triaged as in every review
(`build.review.triage`); an `edit` is collected into `.gtd/REQUIREMENTS.md` and
starts a feedback lap: `re-unwind` reverts the human's code edits, design runs
again (its criteria [stable after review](#acceptance-criteria)), then
`implement.*` with a build turn — never `implement.applying` — then the quality
lap and the review again. A custom workflow ending in `afterTail` runs the same
lap, without the `criteria-ids` check. `seam.naive` and `seam.judge` never run
again once judged, so a seam a re-plan turns up is built unjudged and
unrefactored; a wrong or missing refactor means `gtd abandon` and a restart.

**Upgrading:** the quality lap's notes are decided at the finding gate
(`build.quality.gate`, `mode: "findings"`), and every final review is a
reviewer's walkthrough with one `## Quality lap` summary chunk — no answer boxes
for the lap's notes, no ranking. `build.review.composing` and
`build.review.ranking` (and their `refactor.build.*` twins) are gone, and
`BuildTailOptions` loses `walkthrough`; a config still passing it is ignored. A
`LensReport` no longer carries `notes`: `finish` gets `fixed`, `gateFixed`,
`dropped`, `noise` and `unresolved`. A process past its quality lap — resting at
a review, or anywhere after `build.quality.triage` — no longer replays: finish
or `gtd abandon` open reviews before upgrading. A driver or fixture scripting
the lap scripts `build.quality.gating` (a script step) and the human gate
`build.quality.gate` whenever a note or noise is left, then
`build.review.reviewing` (an agent turn) where it scripted
`build.review.composing`, and `build.review.carrying` when the lap left anything
to list. A repository that formats its steering files declares a `findings` mode
beside `qa` and `review`.

**Upgrading:** a `feature` review marking a `Risk:` runs
`build.review.fix.risks.fixing` (and `refactor.build.review.fix.risks.fixing`)
straight after the reviewer turn, with no `build.review.ranking` or
`build.review.carrying` before it. A process resting at that fix, or at the
re-review after it, no longer replays: finish or `gtd abandon` it before
upgrading. A driver or fixture scripting a risk-marking review drops that first
ranking and carrying.

**Upgrading:** a `won't fix` or own answer at a `feature` or `review` review now
runs `build.review.standards.judge` (and
`refactor.build.review.standards.judge`) before anything is routed. A process
resting past a review round that held one — at its triage, nit fix, question
answer or collecting turn — no longer replays: finish or `gtd abandon` it before
upgrading. A driver or fixture that answers a note `won't fix` or in its own
words scripts that judge too (land it without a verdict to keep nothing).
Workflow-kit's `ReviewPolicy` gains optional `settles`, `learn` and `pending`,
and `routeNotes` an optional fifth argument.

**Upgrading:** `feature`'s review notes carry answer boxes and nothing is
deferred. `build.review.defer` and `refactor.build.review.defer` are gone: a
process resting at either no longer replays — finish or `gtd abandon` it first.
A `could` edit note is re-planned like any other. A driver or fixture that signs
off a review holding notes ticks one box per note first. Workflow-kit's
`Verdict` has no `defer`, and `ReviewPolicy` loses `defer` and gains an optional
`decided`. A `## Deferred review notes` section already in `.gtd/TODO.md` is no
longer kept out of a new process's triage: delete or move it before starting
one.

**Upgrading:** `feature`'s final review is ranked: after the reviewer turn
`build.review.reviewing`, the judge step `build.review.ranking` runs (once per
batch), then `build.review.carrying` — now on every review with a chunk. A
`feature` process resting at `build.review.carrying` or later in its review no
longer replays: finish or `gtd abandon` it before upgrading. A driver or fixture
scripting `feature`'s review scripts `build.review.ranking` too (landing it
without a verdict lists every chunk as `critical`), and expects each chunk of
`.gtd/REVIEW.md` led by its tier line and the chunks reordered.

**Upgrading:** the refactor's review is written by a reviewer too. A `feature`
process resting at `refactor.build.review.composing`, or at any later step of
the refactor's review, no longer replays: finish or `gtd abandon` it before
upgrading. A driver or fixture scripting `refactor.build.review.composing`
scripts the agent turn `refactor.build.review.reviewing` instead, then the judge
step `refactor.build.review.ranking` and the script step
`refactor.build.review.carrying`; a sign-off keeps each chunk's tier line. A
`Risk:` note runs `refactor.build.review.fix.risks.fixing`. Only the `review`
door still composes its review.

**Upgrading:** `feature`'s final review is written by a reviewer again. A
`feature` process resting at `build.review.composing`, or at any later step of
its review, no longer replays: finish or `gtd abandon` it before upgrading. A
driver or fixture scripting `build.review.composing` for `feature` scripts the
agent turn `build.review.reviewing` instead — a walkthrough whose every chunk
points at its code, with one chunk per note the prompt lists — and the script
step `build.review.carrying` when the lap left anything to list. A `Risk:` note
runs `build.review.fix.risks.fixing` again. The refactor's review and the
`review` door still compose theirs. `BuildTailOptions` gains `walkthrough`, and
its `lap` is read again, by the walkthrough reviewer.

**Upgrading:** `review` runs `feature`'s review and fixes its notes in place. A
`review` process past its `review-gate.check` no longer replays: finish or
`gtd abandon` it before upgrading. A driver or fixture scripting the `review`
door's `build.review.reviewing` scripts `build.review.composing` and, with
lenses on, the `build.quality.triage` judge instead; a note there no longer
reaches `build.review.handing-off`, and a `.gtd/REVIEW.md` an older `review`
handed off is still read by `fix`.

**Upgrading:** `feature`'s reviews are composed from the quality lap. A process
resting at `build.review.reviewing`, `build.review.fix.risks.fixing`, a
`build.fix.quality.fixing` turn or `build.quality-unresolved` (or their
`refactor.build.*` twins) no longer replays: finish or `gtd abandon` it before
upgrading. A driver or fixture scripting `build.review.reviewing` for `feature`
scripts `build.review.composing` (a script step) and, with lenses on, the
`build.quality.triage` judge instead.

**Upgrading:** `feature` ends at the review again. A process that ended at
`idle` stays ended; one resting in its quality lap, or at
`build.quality-unresolved` after it, moves on to the review instead of `idle`. A
driver or fixture expecting `feature` to land in `idle` after the quality lap
must sign the review off.

**Upgrading:** finish or `gtd abandon` before upgrading any process whose seam
judge ruled `land`, that overruled a reject at `seam.steer`, or — with no judge
— that has passed `design.gate.answer`: their history names `implement.building`
where the flow now reaches `seam.naive` or `implement.applying`, and replay
refuses it as divergence.

**Upgrading:** finish or `gtd abandon` any process whose seam judge ruled
`refactor-first`: replay now expects `seam.note` after the verdict where its
history names `refactor.deriving`, and refuses it as divergence.

## The refactor review

A review note at the refactor review is collected into `.gtd/REFACTOR.md`, and
`refactor.deriving` runs again with the notes under `## Review feedback` — never
`design.triage`. A concern that needs a path outside the strays, a new or
changed test or assertion, or a new flag read cannot be built: abandon and
restart.

A refactor-review round carrying an `edit` note or a code hand-edit whose
collecting turn writes no `.gtd/REFACTOR.md` and changes nothing is never signed
off: `gtd land` refuses the collecting landing (`refactor-feedback`). A
hand-edit round's refusal names the edited paths. A notes-only round's refusal
names the notes judged `edit`, footnotes included, never praise or questions.
The only way out is `gtd abandon`, which throws away the naive pass, the
refactor and its review. A praise-only round still signs off. A settled round,
one where the human only added thread replies after the in-gate reply turn,
refuses the same way when anything since the review asked for a change: a note
judged `edit` or `nit`, or a hand-edited path. The refusal names them.

Footnotes are judged like line notes. A `- H:` thread left in `.gtd/REVIEW.md`
at the refactor review gets one `- A:` reply and the gate rests again; a thread
folds into `.gtd/REFACTOR.md` only when it asks for a change.

**Upgrading:** four migrations.

- The feature review was dropped (it is back since; see
  [The feature review](#the-feature-review)): `feature` ended after the
  feature's quality lap. A process resting at, or past, any `build.review.*`
  step of the feature (including a feature feedback lap) no longer replayed:
  finish it with the gtd that started it, or `gtd abandon` it, before upgrading.

- `GTD_FLAG_NAIVE_PASS`, its `flag_naive_pass` setting and the architecture and
  package path are gone: every process takes the naive-pass path. A process
  started on the old path (with the flag off — the default) no longer replays at
  any rest from `architecture.*` on — `architecture.*`, `packages.*`, and every
  `build.*` step after them — and must be finished or `gtd abandon`ed before
  upgrading; one resting at `idle`, `unwind`, `start-gate.*` or `design.*` on
  its first lap keeps replaying, onto the naive pass; one on a review loop-back
  lap has `architecture.*` in its history and must be abandoned too.
  `--var flag_naive_pass=…` is refused as undeclared, and a `config.skills` or
  `config.access` key on `architecture`, `architecture.decompose` or
  `packages.item*` fails every command: move it to the `implement*` scope. The
  `architecture`, `packages`, `packageItem`, `nextPackage`, `declaredTests`,
  `requireDeclaredTests`, `author`, `decompose`, `answerTechnicalQuestions`,
  `build` and `fixSuite` exports, the `ARCHITECTURE` constant and the
  `.gtd/ARCHITECTURE.md` steering entry are removed; `planAndBuild` takes only
  its base; `buildFeature` is everything after design. `GTD_FLAG_RISK_TIER` no
  longer needs the removed flag: an old-path process that started with it on and
  replays onto the naive pass records the tier from then on, and with no
  `## Risk Tier` section that tier is `high`.
- `seam.approve` is gone; the refactor's review sign-off is the approval. A
  naive-pass process from 27.5.0 or later whose judge ruled `refactor-first` no
  longer replays at any rest from that verdict on — `seam.approve`, every
  `refactor.*` step, and every `implement.*` and `build.*` step after the
  refactor — and must `gtd abandon`. Processes that rest at `design.*`,
  `seam.naive`, `seam.judge`, `seam.steer`, or past a `land` verdict short of
  the feature review keep replaying.
- `seamBuild(tier)` became `seamBuild(base)` and resolves `{ reference, base }`.
  It no longer runs `implement`; a custom workflow calls `implement` itself.
- `seamBuild(base)` resolves `land: true` when the pass is the implementation
  (`land`, an overruled `reject`, or no release flag asked for, where it runs no
  judge); pass its `reference` on as `implement({ naive: reference })` to apply
  it at `implement.applying`. Without `naive`, `implement` builds fresh as
  before.
- On `refactor-first`, `seamBuild(base)` also resolves `rebuild` (the refactor
  note and the naive pass's acceptance tests); pass it on as
  `implement({ rebuild })` to quote the note and name the tests to carry over.

With `GTD_FLAG_RISK_TIER` on, `design.triage` proposes a risk tier (`low` or
`high`, with a one-line reason) under `## Risk Tier` and the signals to watch
after merge under `## Production Signals` in `.gtd/REQUIREMENTS.md`. Edit the
first word under `## Risk Tier` at `design.gate.answer` to change the tier; a
missing or unreadable tier means `high`. The design gate's landing records
`Gtd-Mark: risk-tier=<low|high>` and one `Gtd-Mark: production-signal=…` per
signal; no step is added.

A third failed attempt — a `reject`, a test fault or a red `seam.check` — rests
at `seam.steer`. Two ways forward, then `gtd land`:

- **Steer** — edit `.gtd/REQUIREMENTS.md`; `seam.naive` runs again with a fresh
  retry budget. An edit together with an approval counts as steer.
- **Overrule** — land a clean tree. After a test fault the last attempt goes on
  to `seam.check` as it is, with a fresh retry budget, and later passes of this
  seam are not checked for test faults again: **its tests may not survive a
  refactor**. After a `reject` the implementation is built against the last
  attempt with no refactor: **overrule ships the seam the judge objected to**,
  unaddressed. After a red check the last attempt goes on to `seam.judge` as it
  is, with a fresh retry budget: **its acceptance tests never passed**, and only
  the implementation's health loop makes the suite green. The choice is recorded
  in history.

After either, `seam.clear` removes a red check's `.gtd/FEEDBACK.md`.

**Upgrading:** finish or `gtd abandon` any process that has landed a
`seam.naive` turn: replay now expects `seam.check` (or, for a turn whose tests
fall short, another `seam.naive`) after it. One resting at `seam.naive` or
earlier keeps replaying; its next naive turn needs ID-tagged tests.

The [`seamAllow`](#settings) setting is the judge's allowlist.
`GTD_FLAG_RISK_TIER` is recorded as `flag_risk_tier` when a process starts, so a
process keeps the setting it started with whatever the environment does later.

## Removed: slices and continuations

**Upgrading:** `feature` builds every change in one pass — one naive pass, one
build, one quality lap, one review — however many criteria it has: split a big
change into separate processes before you start. `design.slicing`,
`.gtd/SLICES.md`, the numbered `feature-<n>`/`refactor-<n>` steps, continuations
(`<phase>.continue.*`, `<phase>.fresh.*`, `<phase>.oversized`) and
`.gtd/HANDOFF.md` are gone, and so are the `sliceMaxCriteria`, `continuations`
and `continuationStall` settings, the `contextLimit` factory option, a step's or
a scope's `context` option, `slice()` from `@pmelab/gtd/flows`, `gtd slices`,
`gtd summary --slice` and `gtd context-hook`. Finish or `gtd abandon` a
`feature` process resting in a slice past its first, or in a continuation,
before upgrading: replay refuses its history as divergence. A config passing a
removed setting or option fails to load: drop it. Re-run `gtd install` (and
replace a `gtd-build` it wrote) so no Claude Code hook still calls
`gtd context-hook`.

**Upgrading:** every quality lap is triaged, and `build.quality-unresolved` is
gone. Finish or `gtd abandon` a `fix` or `cleanup` process past its quality lens
turns, or any process past `build.fix.quality.fixing` whose fix turns left
findings: replay now expects `build.quality.triage` and `build.quality.closing`
there and refuses the history as divergence. A driver or fixture scripting such
a lap scripts the `build.quality.triage` judge, and `build.quality.closing` (a
script step) while `.gtd/QUALITY.md` is still there after the fix turns, and
`build.review.carrying` (a script step) after `fix`'s and `cleanup`'s reviewer
turn when the lap left anything. A config calling `tail()` passes no `triage`
option — every lap triages — and its `finish` receives the report;
`fixQualityFindings` is gone.

## Skills and access

The workflow's scopes, addressable by a `config.skills` or `config.access` entry
(see gtd's configuration,
[Skills](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#skills)
and
[File access](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#file-access)):

`design`, `seam`, `implement`, `implement.fix.suite`, `implement.health`,
`refactor`, `refactor.fix.suite`, `refactor.health`, `refactor.build`,
`refactor.build.health`, `refactor.build.fix.quality`, `refactor.build.review`,
`refactor.build.review.fix.nits`, `refactor.build.review.fix.risks`, one
`refactor.build.quality.<lens>` per `refactorQualityReviews` entry, `build`,
`build.health`, `build.fix.quality`, `build.review`, `build.review.fix.nits`,
`build.review.fix.risks`, and one `build.quality.<lens>` per `qualityReviews`
entry.

A nested scope with no entry of its own inherits its parent's list, so a key on
a parent reaches every scope beneath it that sets none. The group scopes
`build.fix`, `build.review.fix`, `build.quality`, `refactor.fix` and
`implement.fix` run no turn and carry no key, nor do `seam.judge`, `seam.steer`
and `seam.by-hand`. A custom workflow's own scopes are addressable through its
own `skills` export (see
[Using it in `gtd.config.ts`](#using-it-in-gtdconfigts)); the export may be a
function of the resolved vars, and must list every scope holding an agent step.
The type can check an entry's VALUE (an array of strings) but never its KEY,
since scope names come from the workflow actually in play — there is no editor
autocompletion of scope names here.

A key that is not a scope running a turn is a load error, exit 1 — a group scope
such as `build.fix`, or a step name rather than its scope. The message lists the
known scope keys. Keying config on a scope's full name widens what renaming a
scope breaks: it also orphans every `config.skills` entry naming it, which
becomes an unknown key and exits 1.

`qualityReviews` (a process setting, not a `skills` entry — see
[Settings](#settings)) and the `build.quality.<lens>` keys are a pair:
`qualityReviews` decides how many quality-lap turns run, one per lens, and each
lens is its own scope, keyed `build.quality.<lens>`. By default that scope's
skills ARE the lens; a `build.quality.<lens>` entry REPLACES them with the
configured list, leaving the prompt body's own mention of the lens untouched.
Such a key is valid only while the lens is listed in `qualityReviews` (for a
`refactor.build.quality.<lens>` key, in `refactorQualityReviews`), judged
against the running process's recorded settings, or against the workflow's
settings, `GTD_<NAME>` and `--var` when no process is underway. A key added for
a lens mid-process errors until that process finishes.

### Access defaults

Only planning and review scopes are restricted, and only on writes; no scope
restricts reads. Build and fix scopes carry no entry, except `refactor`:
`refactorFirst` restricts its writes to the strays and `.gtd/**` itself, and a
`config.access.refactor` entry replaces that wholesale. Every `refactor.build.*`
scope inherits that restriction, except the scopes below that set their own.
`refactor.build.review.fix.nits` and `refactor.build.review.fix.risks` carry the
same strays-plus-`.gtd/**` limit, set at run time; a `config.access` entry on
the fix scope outranks it, while a `config.access.refactor` entry does not reach
it.

| Scope                                                               | `write`                          |
| ------------------------------------------------------------------- | -------------------------------- |
| `design`                                                            | `[]`                             |
| `build.review`                                                      | `.gtd/REVIEW.md`                 |
| `build.review.fix.nits`, `build.review.fix.risks`                   | `{}` (reopened: fixes edit code) |
| `build.quality.<lens>`                                              | `[]`                             |
| `refactor.build.quality.<lens>`                                     | `[]`                             |
| `refactor.build.review`                                             | `.gtd/REVIEW.md`                 |
| `refactor.build.review.fix.nits`, `refactor.build.review.fix.risks` | the strays, `.gtd/**` (run time) |

## Settings

Overridable as [factory options](#factory-options) or through `GTD_<NAME>`:

```ts
// gtd.config.ts — overriding the workflow's testCommand
import { feature } from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export default feature({ testCommand: "npm run test:ci" })
```

```bash
# highest precedence — beats the workflow's own value above
GTD_TESTCOMMAND="npm run test -- --bail" gtd next
```

The workflow puts a preamble naming the skills an agent step loads (its scope's
`config.skills` entry — see [Skills and access](#skills-and-access)) ahead of
that step's prompt; an empty entry switches it off for that scope. A preamble in
a workflow of your own must carry three clauses, or it is unsafe: load only what
your harness has and skip the rest silently; THE STEP'S OWN FILE FORMAT AND
COMPLETION CONDITION OUTRANK ANYTHING A SKILL SAYS; never turn the turn
interactive, because no one is at a keyboard. The precedence clause is
load-bearing — the preamble sits above the step's own format prose, so a skill
that reflows the steering file changes which branch the flow takes next.

**Environment settings:**

- **`testCommand`** (`npm test`) — the suite every health check, `seam.check`
  and baseline gate runs. It is interpolated into a POSIX `sh` script, so keep
  it sh-compatible.
- **`plannerModel`** (`smart`) / **`coderModel`** (`base`) — the `model` hints
  of the planning/reviewing steps (design triage, the review, the `correctness`,
  `owasp-security`, `spec-challenge` and `criteria-coverage` lenses) and of the
  building/fixing steps (the naive pass, implementation, refactor, every fix
  loop, the `conventions`, `ponytail-review` and `test-audit` lenses). A lens
  hint in `qualityReviews` or `refactorQualityReviews` wins over either. Judge
  steps such as `seam.judge` carry no hint: their model is the judge provider's
  (see gtd's
  [Judge settings](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#judge-settings)).

**Process settings:**

- **`judgeIdenticalMinP`** (`0.7`) — the confidence an "identical failure"
  verdict at `health.judge` needs before a red streak escalates early, and a
  "progress" verdict needs to earn the extra fix turn at the cap. Blank,
  non-numeric or non-finite means it can never be cleared, so both are off.
- **`reviewNoteActionable`** (`0.7`) — the floor a non-`edit` verdict
  (`question`, `nit`, `praise`) on a review note must clear at
  `build.review.triage` and `refactor.build.review.triage`. Below it, the note
  counts as `edit` and goes to the collecting turn and a replan. A note whose
  evidence was cut, or that got no verdict, also counts as `edit`. Blank makes
  every note `edit`. Triage answers are keyed `note-<n>`.
- **`reviewSeverityMinP`** (`0.7`) — the confidence each severity judge answer
  on a review note must clear. Every tiered note gets a `critical`, `should` or
  `could` tier from four yes/no questions, keyed `note-<n>.<question>`:
  `security`, `reversibility`, `blastRadius`, `newConcept`. An unclear, cut or
  below-floor answer makes the note `critical`, never `could`. Blank makes every
  tiered note `critical`. A leading `! ` (bang, space) on any human review note
  forces `critical` and skips every judge question.
- **`standardMinP`** (`0.8`) — the floor a `yes` on "is this answer a reusable
  standard?" must clear at `build.review.standards.judge` (and
  `refactor.build.review.standards.judge`) before the answer is kept in
  `.gtd/STANDARDS.md`, and a `no` on "does it contradict this one?" must clear
  before it is kept without asking you. Blank keeps none and asks no judge. See
  [learned standards](#learned-standards).
- **`qualityTriageMinP`** (`0.7`) — the floor a `mechanical` or `noise` verdict
  on a quality finding must clear at `build.quality.triage` (and
  `refactor.build.quality.triage`). Below it, the finding is `design` and
  reaches the finding gate as a note. Blank makes every finding `design`.
  Answers are keyed `Q<n>`. See
  [the triaged quality lap](#the-triaged-quality-lap).
- **`refactorFlagPattern`** (`\bGTD_FLAG_\w+`) — the regular expression whose
  matches `refactorFirst` counts as flag reads (see
  [`refactorFirst`](#refactorfirst)). Blank or an invalid expression fails
  before the refactor starts, as does a pattern that matches the empty string.
  The default matches gtd's own `GTD_FLAG_<NAME>` naming; most repositories
  should set their own.
- **`seamAllow`**
  (`**/*.test.*, **/*.spec.*, **/*.feature, **/tests/**, **/test/**, **/__tests__/**, .gtd/**`)
  — the paths the [naive pass](#the-naive-pass-path) may change without the
  judge counting them as strays. Comma-separated globs, trimmed, blanks dropped;
  no brace alternation (`{a,b}` splits at the comma). A file the pass newly adds
  is allowed by its exact path, never as a glob: a new `src/a*.ts` does not
  cover a modified `src/a.ts`.
- **`naiveTest`** (`false`) — whether a person tries every green naive pass by
  hand at `seam.try`, before the seam judge, any refactor, the implementation or
  the quality lap; notes or edits there send it back to `seam.naive`. See
  [The naive test](#the-naive-test). Set it as the factory option
  `feature({ naiveTest: true })` (or `--var naiveTest=true`,
  `GTD_NAIVETEST=true`). Any value but `true` or `false` refuses the landing
  that would start the process. Pinned at process start.
- **`flag_risk_tier`** (`0`) — this workflow's own release flag: `1` when
  `GTD_FLAG_RISK_TIER` is on (`1` or `true`), recorded at process start (see
  gtd's
  [Feature flags](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#feature-flags)).
  Not a factory option; `--var flag_risk_tier=1` is the only override. Off, no
  tier is asked for and no commit carries a `Gtd-Mark:`. See
  [the naive-pass path](#the-naive-pass-path).
- **`judgeBudgetBytes`** (`32768`) — the total byte budget split across one
  judge step's evidence keys. Must be a positive integer; blank, zero, negative
  or fractional values fail the step rather than disabling the bound.
- **`qualityReviews`**
  (`correctness, owasp-security, ponytail-review, test-audit, conventions, spec-challenge, criteria-coverage`)
  — sets the quality lap `build.quality` runs ahead of the human review: one
  turn per comma-separated lens, in order. It is the one skill control that is a
  process setting rather than a `skills` entry — it decides the turn COUNT. Each
  lens is its own scope, keyed `build.quality.<lens>`; by default that scope's
  skills ARE the lens, and a `build.quality.<lens>` entry (see
  [Skills and access](#skills-and-access)) replaces them, valid only while the
  lens is listed here. Every round pays for it, so extend the list only as far
  as that is worth paying for — each lens adds about 1–1.5 min and about $0.5
  per run; blanking it disables the lap. `correctness` (loads
  `code-review-and-quality`), `conventions`, `spec-challenge` and
  `criteria-coverage` are built-in lenses whose brief rides in the prompt.
  `criteria-coverage` gets the requirements the change was built to, quoted in
  its prompt, and writes one finding per acceptance criterion no test exercises;
  where there are none (the `review` and `fix` workflows) it runs no turn; in
  `feature` each finding is then [triaged](#the-triaged-quality-lap), elsewhere
  every finding any lens writes, blocking or not, is fixed by the one fix turn.
  An entry may carry a model hint, `<lens>=<model>` (split at the first `=`,
  both sides trimmed; a blank hint is none): `test-audit=smart` runs that lens
  on `smart`. A lens without one runs on `coderModel` when it is `conventions`,
  `ponytail-review` or `test-audit`, else on `plannerModel`. The hint is no part
  of the lens's name: its scope stays `build.quality.<lens>`. See
  [Setup](./setup.md#extending-the-quality-review-lap).
- **`refactorQualityReviews`** (`correctness, ponytail-review, conventions`) —
  the quality lap the refactor review runs, one turn per comma-separated lens,
  as `qualityReviews` does for the feature. `qualityReviews` does not reach it,
  and a lens left out never sees the refactor (the feature lap reviews from the
  refactor's sign-off); blank runs no refactor quality lap. Each lens is its own
  scope, keyed `refactor.build.quality.<lens>`. Entries take the same
  `<lens>=<model>` hints, read from this list alone.
- **`reviewBase`** (empty) — the commitish `--workflow review` reviews from
  (`gtd door review` sets it).

The prompts' wording — the voice below, the personas, the shared rules — is not
a variable: a workflow that wants different words writes its own prompts,
reusing the workflow's steps and phases where it can (see
[Using it in `gtd.config.ts`](#using-it-in-gtdconfigts)).

## The voice

The workflow ships its own writing voice for the files it generates — the
default, not an opt-in. It is a specialisation of the "Spartan" output style
from [alexgreensh/attention-span](https://github.com/alexgreensh/attention-span)
(AGPL-3.0), written from a reading of that project's version `0.6`: its own
prose stating the same density discipline, rewritten for deliverables (files
that run as long as the work needs) rather than chat replies. No upstream text
ships in the bundle. This is a point-in-time derivation with no refresh
mechanism — it will silently go stale as upstream moves on.

- **The voice itself** is injected into every agent step that writes a
  deliverable: `.gtd/REQUIREMENTS.md` and `.gtd/REVIEW.md`.
- **A format contract** follows it for machine-read files: the format contract
  (headings, checkbox rows, marker lines) outranks the voice, and a violation
  refuses the turn. It is injected at the steps whose output a parser reads
  (`design.triage`, `build.review.reviewing`, `build.review.collecting`).

Files a script writes carry no injected voice: `.gtd/FEEDBACK.md` holds verbatim
test output plus a HEAD stamp.

## Escalation

A red suite that stays red past three fix turns (four while it makes progress,
below) — or that `health.judge` calls "identical" to the previous round —
escalates instead of retrying forever, counting escalation rounds since the last
green check:

- **Under 2 rounds** — an agent turn at `health.describe` reads
  `.gtd/FEEDBACK.md`, `.gtd/PRIOR_FEEDBACK.md` when present, and the code the
  earlier attempts touched, then writes `.gtd/ESCALATION.md`: what is failing,
  why the attempts did not resolve it, and concrete approaches to try next. The
  process then waits at the human gate `health.stop`: edit the file or land it
  untouched — either way it becomes the next fix turn's primary instruction.
- **At 2 or more rounds** — no third document is written. The last
  `.gtd/ESCALATION.md` stays in place and the process waits at
  `health.exhausted`, naming both that file and `.gtd/FEEDBACK.md`. Editing the
  document there is what gives the next attempt anything new to try; landing it
  untouched tries the same analysis again.

When `health.judge` calls the round that reaches the cap "progress" — still red,
but closer to green — with at least `judgeIdenticalMinP` confidence, one more
fix turn runs first; the round after it escalates without asking the judge. The
extra turn comes once per run of fix turns, so each escalation stop starts a run
with its own. It never applies when the budget cut either report or one of them
was empty. A "new-failure" verdict never escalates early.

A round is one `health.describe` turn since the last green check; editing the
file at the human gate never spends one. Both gates release straight into the
caller's fix step (`build.fix` or `implement.fix.suite.fixing`), so the turn
that consumes the document is the very next one. `.gtd/ESCALATION.md` is
free-form prose with no mode of its own.

**Upgrading:** finish or `gtd abandon` any process whose history has a
`health.judge` landing that answered "progress", at `judgeIdenticalMinP`
confidence, on the round reaching the cap, even if it has moved on since: that
landing now leads to an extra fix turn, so its history no longer replays. A
`gtd.config.ts` calling `healthy` from `@pmelab/gtd/workflow-kit` passes
`compare` in place of `sameFailure`, resolving `"identical"` where it resolved
`true`, `"progress"` for a round closer to green, or `undefined`.

## Re-check before a person

No red check reaches a person without running once more. Before escalating, the
health loop re-runs the suite as `health.recheck`; a red baseline gate
(`start-gate`, `review-gate`, `rollout`'s `suite`) re-runs it as
`<gate>.recheck` before resting at `<gate>.blocked`. No judge is asked. Green on
the re-run continues as if the check had passed, and that landing carries
`Gtd-Mark: flaky=<check>` (`health.check`, or `<gate>.check`), which
`gtd history metrics` counts under the re-check's full step name. A green
re-check also resets the escalation rounds, as any green check does. Red again
escalates or rests as above.

**Upgrading:** finish or `gtd abandon` any process whose history has ever
escalated (reached `*.health.describe` or `*.health.exhausted`) or rested at a
`*.blocked` gate, even if it has moved on since: its history no longer replays,
since a re-check now comes first.

## Rolling out and cleaning up a release flag

Two workflows move a release flag through its life. Export them from
`gtd.config.ts` — `gtd-wf config default` does not — and start each through its
door:

```ts
import {
  rollout as rolloutWorkflow,
  cleanup as cleanupWorkflow,
} from "/home/me/.local/share/gtd/workflows/dist/default.mjs"

export const rollout = rolloutWorkflow()
export const cleanup = cleanupWorkflow()
```

```bash
gtd door rollout <flag>
gtd door cleanup <flag>
```

`gtd --workflow rollout --var flag=<name>` (likewise `cleanup`) starts the same
process. A door with no argument is refused (see below).

- `flag` is the flag's name in the registry; it is required.
- `flagRegistry` is a factory option
  (`rollout({ flagRegistry: "src/flags.ts" })`), default `src/flags/index.ts`:
  the file declaring the flags, read as text: each flag is a flat object literal
  such as
  `{ name: "beta", owner: "me", expiry: "2027-01-01", kind: "release", defaultOn: true }`
  (`defaultOn` optional). Comments and string contents are not entries.
- **Rollout** takes a non-default-on release flag and has an agent set
  `defaultOn: true` on its entry, and nothing else. The suite must stay green.
  There is no review: once the suite passes, step `rollout.mentions` lists every
  line in a tracked file, `src/` help strings and `docs/` alike, that names the
  flag (as `GTD_FLAG_<NAME>`, `flag_<name>` or the bare name, case-insensitive),
  outside the registry and `.gtd/`, and the process ends. The list edits no file
  and leaves none behind: the closing commit records
  `Gtd-Mark: flag-mentions=<total>` and one
  `Gtd-Mark: flag-mention=<path>:<line>` per listed line (the first 50), and the
  closing message `gtd summary` prints carries the same lines, then "…and N
  more:" with a `git grep -niIE` command over tracked files, excluding the
  registry and `.gtd/`, matching the same three forms. Fix that prose by hand,
  or leave it for cleanup. These limits also bind the mentions step
  (`rollout.mentions`) and a human's fix at `rollout.suite.blocked`: each may
  touch only the flag's registry entry (`.gtd/FEEDBACK.md` aside), or the
  landing is refused.
- **Cleanup** takes a default-on release flag, deletes its entry and every
  `GTD_FLAG_<NAME>` check from `src/` (only `.ts`/`.tsx` files there are
  scanned), keeping the flag-on path, then runs the review. A review note ends
  the process; `gtd door fix` works it off. Those checks re-run after every
  later agent turn (fixes, escalation, quality lenses, the review's own turns)
  and a human's escalation landing, over the `src/` files that turn changed —
  but not after the human's review sign-off.

Refusals, each exiting non-zero with the text on stderr:

| Text                                                                                         | When                                                                            |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `gtd: <workflow> needs --var flag=<name>`                                                    | no `flag` var                                                                   |
| `gtd door <rollout\|cleanup>: missing arguments — usage: gtd door <rollout\|cleanup> <flag>` | `gtd door rollout` or `gtd door cleanup` with no flag                           |
| `gtd: <workflow>: no flag "<name>" in <registry>`                                            | name not in the registry                                                        |
| `gtd: <workflow>: flag "<name>" is <kind>, not release`                                      | not a release flag                                                              |
| `gtd: rollout: flag "<name>" is already default-on`                                          | rollout of a default-on flag                                                    |
| `gtd: cleanup: flag "<name>" is not default-on — roll it out first`                          | cleanup of a flag still default-off                                             |
| `gtd land: rollout-only: <paths> changed — rollout may only set …`                           | rollout (agent, mentions step or human fix) touched a file besides the registry |
| `gtd land: rollout-only: other edits in <registry>: <faults>`                                | rollout (agent, mentions step or human fix) edited beyond that one field        |
| `gtd land: cleanup: <registry> still declares flag "<name>"`                                 | cleanup left or restored the registry entry                                     |
| `gtd land: cleanup: <paths> still names GTD_FLAG_<NAME>`                                     | cleanup left or reintroduced an env-var check under `src/`                      |

New step names in both workflows are this workflow's public API.
