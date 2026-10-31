# gtd workflows

The workflows in this repository run on gtd's engine. This glossary holds the
words the `default` workflow adds; the engine's own words (workflow, step, rest,
process, gate, guard, steering file, …) are in gtd's
[CONTEXT.md](https://github.com/pmelab/gtd/blob/main/CONTEXT.md).

## Language

### The `default` workflow

`feature` (the ordinary start), `review` (`feature`'s review since a base, its
notes fixed in place), `fix` (repair a red baseline), `rollout` and `cleanup`.

**Release flag**: A feature flag whose registry entry has `kind: "release"`,
optionally `defaultOn: true`. **Rollout** sets `defaultOn: true` on one;
**Cleanup** deletes a default-on one, keeping its flag-on path. The **flag
registry** is the file declaring the flags, read as text.

**Flag read**: A match of `refactorFlagPattern` in a changed file of the user's
project. Not a
[feature flag](https://github.com/pmelab/gtd/blob/main/CONTEXT.md#feature-flag):
the pattern defaults to the `GTD_FLAG_` naming but names whatever the repository
gates with. The refactor may not add one.

**Lens finding**: One `## ` chunk a quality lens writes to `.gtd/QUALITY.md`. A
judge calls each `mechanical` (the fixer fixes it), `noise` (set aside) or
`design` (a note for the [finding gate](#finding-gate)); unsure is `design`.
_Avoid_: issue, comment, review item

**Finding gate**: The human gate after the quality lap (`build.quality.gate`)
where each open lens finding, and each one the judge called noise, is ticked
`fix` or left to drop. A ticked finding is fixed, never re-planned. _Avoid_:
triage (taken by `design.triage`; `quality.triage`/`review.triage` are judges)

**Acceptance criterion**: One `- AC-<n>: …` line under `## Acceptance Criteria`
in `.gtd/REQUIREMENTS.md` — a checkable statement of observable behaviour the
build must make true, never how it is built. A lap keeps the IDs the file
already holds; only a design lap changes the list. _Avoid_: requirement (the
whole file), story, done-when

**Naive pass**: The `seam.naive` turn: the requirements implemented directly,
kept as a
[kept tip](https://github.com/pmelab/gtd/blob/main/CONTEXT.md#kept-tip). Applied
as the implementation when the [seam judge](#seam-judge) rules `land`, a human
overrules its `reject`, or no [release flag is requested](#requested-flag);
otherwise only reading material for a rebuild. Done only when the suite is green
with it applied; it need write no test.

**Naive test**: A person trying a green [naive pass](#naive-pass) by hand at
`seam.try`, with `naiveTest` on: applied to the working tree, then signed off by
a clean landing or sent back to a new naive pass with notes or edits. The only
hands-on check the workflow has. _Avoid_: hands-on test, prototype test.

**Acceptance test**: A test file a naive pass adds or changes — one test per
behaviour its [acceptance criteria](#acceptance-criterion) describe, never named
after a criterion's ID. It reaches only code that existed before the pass, so it
survives a reset and refactor. Whether every criterion is exercised is the
`criteria-coverage` lens's finding, not a refusal. _Avoid_: AC test, criterion
test

**Stray**: A path a naive pass changed that `seamAllow` does not match (a newly
added file never counts).

**Seam**: The change to existing code a task needs beyond its own new code, as
the strays show it.

**Seam judge**: The `seam.judge` step: rules `land`, `refactor-first` or
`reject` on a naive pass's strays.

**Answer**: The one box a human ticks under a review chunk that carries
`Tick exactly one:` boxes — a standard conflict, or a note added with its own —
`fix as suggested`, `won't fix`, or their own text over `_your answer_`. The
review gate lands only when every such chunk holds exactly one. _Avoid_: verdict
(the judge's word), defer (gone)

**Standard**: One bullet in `.gtd/STANDARDS.md` — a rule the human set by
answering a review note (`won't fix` or their own words), kept once a judge
calls it reusable and handed to every later agent turn. An **undecided**
standard contradicts a kept one and waits on the human's answer in the review.
_Avoid_: rule, preference, convention (that is a lens), learned taste

**Refactor note**: `.gtd/REFACTOR-NOTE.md`, written by `seam.note` from the
whole [naive pass](#naive-pass) on `refactor-first`: which seams the refactor
opens and the shape each takes. Read by the refactor and the
[rebuild](#rebuild); removed when the implementation closes.

**Rebuild**: The `implement.building` turn after a refactor: the change
re-implemented on the refactored base, behind a release flag, with the naive
pass as reference, asked to carry over every one of the naive pass's
[acceptance tests](#acceptance-test). _Avoid_: re-implementation, second pass

**Requested flag**: What `.gtd/REQUIREMENTS.md`'s `## Release Flag` section asks
for — `new` or `existing: <NAME>` — written only when the sketch asks for a
flag. Without one the change ships unflagged, with no seam judge or refactor.
_Avoid_: flag mode (removed).

**Rollout**: The workflow that turns one release flag default-on — an agent
edits only its registry entry, no review. _Avoid_: beat (that is the driver's
unit), flip beat

**Cleanup**: The workflow that removes one default-on release flag and its
checks, keeping the flag-on path, then reviews. _Avoid_: beat, sweep

**Unwind**: The step (`unwind`) that reverts the entry commit's diff — the
change that started the process, whether a hand-edit to real code or a scratch
note — back out of the working tree, leaving it identical to the process's start
commit. The input's intent isn't lost: it survives in history for
`design.triage` to read.

**Concern**: One ordered, independently greenable unit of work `design.triage`
groups the process's start diff into.

**Product concern** / **Technical concern**: A concern's classification — a
product concern is a user-facing/requirements decision, raised (if it has an
open point) by `design.triage`; a technical concern is an implementation
decision, left to the agent that builds it.

**Triage**: `design.triage`'s own job — reading the diff that started the
process (never rendered into its prompt) and grouping/classifying it into
concerns.

**Risk tier**: `low` or `high` — no middle tier — how much a wrong guess in a
change costs. `design.triage` proposes it in `.gtd/REQUIREMENTS.md`'s
`## Risk Tier` section, the human overrides it at `design.gate.answer`, and a
missing or unreadable tier is `high`. Recorded as a
`Gtd-Mark: risk-tier=<low|high>` trailer, only with `GTD_FLAG_RISK_TIER` on.
_Avoid_: `critical`/`should`/`could`, severity (that is a review note's word).

**Production signal**: One line under `## Production Signals` in
`.gtd/REQUIREMENTS.md`: what to watch after merge to know the change works.
Recorded as a `Gtd-Mark: production-signal=<line>` trailer; nothing checks that
it exists.

**Question gate**: The human answer gate (`design.gate.answer`) the process
rests at only while `.gtd/REQUIREMENTS.md` has an unanswered open question — a
question-free phase skips the human stop entirely.

**Green baseline**: The test run every entry opens with, proving the suite was
already green before gtd changed anything — so a later red run is attributable.

**Review record**: `.gtd/REVIEW.md` — the review of one process, written as
chunks of hunk pointers, and the artifact a reviewer edits to approve or send
back.

**Feedback**: What a human or a check writes back to send work around again — a
review's requested changes, or a failing suite's output.
