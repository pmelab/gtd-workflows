# The default workflow

The `default` workflow is the feature → review → fix workflow gtd used to
bundle. Get it into a repository with `gtd-wf config default` (see the
[README](../README.md#using-a-workflow)); every setting and step is in the
[reference](./reference.md). From where you sit, it has four moments —
everything between them runs without you, with the judged exceptions noted in
steps 3 and 4 below.

1. **You sketch.** Change anything, or write the idea into `.gtd/TODO.md`. Rough
   is fine; it is treated as a sketch, not as work.
2. **You answer questions and discuss.** Planning works out what the thing
   should do and hands you `.gtd/REQUIREMENTS.md` — every process stops there,
   even with no open question. Answer open questions in your editor, in the
   file, and start the loop again; a round that only leaves notes needs no tick.
   Start a footnote with `- H: <question>` to ask something: the agent replies
   with `- A: <reply>` and the process stops at the same gate again. Close a
   thread by replying with a conclusion or deleting it. While a thread's last
   entry is the agent's, moving on is refused. Leave the file untouched and
   start the loop to accept the plan as-is, unanswered questions and all. The
   file lists numbered acceptance criteria (`AC-1`, `AC-2`, …) that bind the
   build, and an `## Impact` section mapping the units and public surfaces the
   change touches — correct it here and the next lap re-explores from your edit.
   Sketch your own criteria under an `Acceptance criteria` heading and, when a
   judge finds every one clear and checkable, they are recorded as they are and
   this moment is skipped: a `design.impact` agent turn writes Impact instead,
   unreviewed. One vague criterion brings the moment back. See
   [Acceptance criteria](./reference.md#acceptance-criteria).

3. **You wait.** The agent first implements the requirements the quickest way
   that works — the naive pass — and a judge reads where it changed code (see
   [the naive pass](#the-naive-pass) below; without a
   [release flag](./reference.md#release-flags), no judge runs). A pass the
   judge lets through is the implementation; one whose seam is refactored first
   is built again test-first. Then it is checked against the full suite
   (`testCommand`) and fixed until it passes — so keep that suite fast; the
   workflow has no lighter one. Scenario wording is not frozen: a review's
   `## Scenarios` chunk marks any assertion an existing scenario lost as
   `Weakened:`, so you sign the scenarios off at step 4. After the build the
   quality lap runs. Three points along the process (two without a release flag)
   are judged rather than always asking you outright — each stops and hands you
   a verdict to make (`gtd judge answer`, or land with a clean tree to accept
   the conservative default, which never skips work; `gtd judge run` answers one
   for you — see gtd's
   [judge gates](https://github.com/pmelab/gtd/blob/main/docs/driver.md#judge-gates-an-aware-drivers-env-var-mapping)):
   - After the naive pass: does it land as is, need its seam refactored first,
     or get rejected and retried?
   - Every red round after the first: was the failure identical, new, or
     progress?
   - After you review: is each of your notes an edit, a question, a nit or
     praise?

   gtd itself never calls a judge: the Claude Code mod and the reference driver
   answer these through `gtd judge run` (auto selection: jev when
   `TYPESAFE_API_KEY` is set, else `llm` via `claude`, default model sonnet,
   while the Claude Code mod's own judge subagent stays on `haiku` —
   `--model <name>` overrides); if that fails it shows you the message and
   stops. **The `llm` provider's `p` is self-reported by the model, not a
   measured probability, so a confidently wrong verdict can clear the 0.7 floor
   and skip a gate unattended.**

   Once the change is built, the whole change goes through a qualitative review
   lap before you see anything: seven lenses, one turn each, in order —
   `correctness`, `owasp-security`, `ponytail-review`, `test-audit`,
   `conventions`, `spec-challenge`, `criteria-coverage`. `correctness`,
   `owasp-security`, `spec-challenge` and `criteria-coverage` run on the planner
   model (`smart`), the other three on the coder model (`base`); a
   `qualityReviews` entry `<lens>=<model>` picks a lens's own.
   `criteria-coverage` reads the requirements and the change's tests and writes
   one finding per acceptance criterion no test exercises; with no requirements
   (the `review` and `fix` workflows) it runs no turn. Each traces the change
   from its own angle and records every finding, blocking or not, as its own
   `## ` chunk of `.gtd/QUALITY.md`. A clean turn means approval only when that
   lens found nothing at all. The lenses are the only agentic review: a judge
   (`build.quality.triage`) then classifies each finding — `mechanical` ones are
   fixed by the fix turn (`build.fix.quality.fixing`, up to three turns),
   `noise` is dropped with its `p` recorded as
   `Gtd-Mark: noise=<id> p=<p> <title>`, and `design` ones (questioning a
   criterion or the approach) become notes. An unsure verdict (below
   `qualityTriageMinP`, `0.7`) is `design`; mechanical findings the fix turns
   leave become notes too. **The finding gate** (`build.quality.gate`) then
   stops for you: `.gtd/QUALITY.md` lists the notes, then the noise under
   `# Dropped as noise` so you can overrule the judge, each with one `- [ ] fix`
   box. Tick a finding to have it fixed, optionally with a line of guidance
   below its box; leave it unticked to drop it — landing the file untouched
   drops them all, and guidance under an unticked box is refused. The ticked
   ones go to the same fix turns (up to three), then the suite is kept green;
   what they leave is listed as unresolved, with no second gate. A ticked
   finding is fixed, never re-planned: raise anything bigger in your review. A
   lap with no notes and no noise has no gate. This lap is where code quality is
   looked at, and every round pays for it. It never replaces step 4 — your
   review stays the final gate, and nothing here skips it. The `fix` and
   `cleanup` doors run the same lap and gate before their own review.

   A red suite that keeps failing past a few fix attempts escalates instead of
   retrying forever: an agent turn reads the failing output and writes
   `.gtd/ESCALATION.md` — what's failing, why the earlier attempts didn't fix
   it, and what to try next — and the process stops for you to edit or land
   as-is, handing that document to the next fix turn as its instruction. Two
   such rounds with no fix is the terminal stop: the last analysis stays on disk
   instead of a third being written, and editing it is what gets the next
   attempt anywhere new. A loop the retry judge still calls progress at the cap
   gets one extra fix turn first. Before any escalation or red-baseline stop the
   suite runs once more; a pass there continues without you and is recorded as
   `Gtd-Mark: flaky=<check>` (see
   [Re-check before a person](./reference.md#re-check-before-a-person)).

4. **You review.** After the quality lap a reviewer turn
   (`build.review.reviewing`) walks you through the whole change: `## ` chunks
   grouped by concern, **every chunk pointing at its code**
   (`./path#start-end`), so the phone shows the diff beside each one. gtd
   appends one `## Quality lap` chunk (`build.review.carrying`) listing, for
   reference, what the quality lap did with every finding: **fixed
   automatically** and **fixed at the finding gate** (each with its fixing
   commit), **dropped at the finding gate**, **dropped as noise**, and
   **unresolved after the finding gate**. To reopen one, write a note under its
   line. A review with a chunk pointing at no code is refused
   (`review-pointers`). A pointer note the reviewer opens with `Risk:` is fixed
   before you see the review (`build.review.fix.risks.fixing`), then the review
   is written again over the reviewer's own draft. On `refactor-first` the
   refactor gets a walkthrough of its own first, covering the whole refactor on
   every round, before the feature is built; see
   [the naive pass](#the-naive-pass). Land with nothing changed to approve, or
   write what is wrong. A note added with its own `Tick exactly one:` boxes (as
   `/gtd pr` imports a thread) is answered by its tick instead of judged: fix as
   suggested joins the nit batch below, won't fix drops it and records
   `Gtd-Mark: wontfix=<title>`, your own answer is judged like a note. Approving
   ends the process (at the refactor review, it moves on to the feature);
   feedback is judged note by note, each as `edit`, `question`, `nit` or
   `praise`. An `edit` sends the process back to step 2 for re-derived
   requirements — the built criteria keep their IDs (reworded in place when
   their behaviour changes) and new behaviour gets new ones — then the
   implementation is amended to meet them, with no new naive pass or seam judge,
   the quality lap runs, and you review again. At the refactor review an `edit`
   re-derives the refactor instead. A `question` is answered inline under your
   note and the process stops at the review again — no new plan. A `nit` is
   fixed in one batch, the suite must go green (a red one gets fix turns first),
   then a fresh review of the change stops at the review again. `praise` is
   dropped; a round of only praise signs off. When a round mixes them, questions
   are answered and nits fixed first, then the edits are planned — risk: the
   planning lap may redo nit fixes it touches.

   Each `edit` note also gets a severity tier from four judge questions
   (security, reversibility, blast radius, new concept). Every tier is
   re-planned this round, `critical` first, then `should`, then `could`; nothing
   is deferred. A leading `!` on a note forces `critical` and skips the judge.
   `reviewSeverityMinP` sets the confidence floor (see
   [the reference](./reference.md#settings)). A hand-edit to code always plans a
   lap. Only a confident non-`edit` verdict skips the replan — a note whose
   evidence was cut, or that got no verdict, counts as `edit`. The same
   `gtd judge answer` / conservative-default shape as step 3's own judged
   points.

   **The review learns your taste.** Each won't-fix and each own answer is a
   candidate standard. A judge (`build.review.standards.judge`) asks whether it
   is reusable beyond this note; at `standardMinP` (`0.8`) or above it is kept
   in `.gtd/STANDARDS.md` with no question asked, and the next review lists it
   under `## Standards added`. Every later agent turn — the lenses, the naive
   pass, the build, every fix — is handed the kept standards, so a finding you
   rejected once is not raised again and a rule you wrote is followed, in this
   process and every later one. One the judge does not confidently rule out
   contradicting a standard already kept is not applied: it waits under
   `## Undecided` and becomes a `## Standard conflict <id>` note in the review,
   with its own three boxes — **keep the new one (drop the old)**, **keep the
   old one (discard the new)**, or **your own wording**, which replaces both —
   and the review does not sign off until it is answered. `.gtd/STANDARDS.md` is
   committed and yours to edit; the workflow rewrites it as one bullet per
   standard when it learns.

You never talk to it. Every exchange is a file in `.gtd/` that you edit in your
own editor, and every answer you give is a commit. Your test suite is the gate
throughout: a red baseline stops the process before it starts, and a red build
is fixed before review.

## The other workflows

The workflows are named `feature` (the ordinary start above), `review` and
`fix`. `review` and `fix` never plan. Each brings its own door. This command:

```bash
gtd door review <commitish>
```

starts a review of everything from `<commitish>` to HEAD — the same review a
`feature` process ends with, minus planning and building. A green gate, then the
quality lenses: mechanical findings are fixed, the rest wait at the finding
gate, then a reviewer walks you through the change in `.gtd/REVIEW.md`, with the
lap's summary. A nit note is fixed in place; a note asking for a change is
collected into `.gtd/REQUIREMENTS.md` and built by one `feedback.fixing` turn,
with no design phase and no criteria — under the health loop, then it asks for
your review again. Sign off and it closes; nothing is left behind. A note asking
for new behaviour belongs in a `feature` process: sign off and start one.
`gtd door fix` repairs a red baseline as its own reviewed commit; a note at its
review is left in `.gtd/REVIEW.md` (beside the reviewer's original,
`.gtd/REVIEW.orig.md`) for the next `gtd door fix`, and until that runs,
starting `feature` or `review` is refused — remove both files to abandon the
hand-off. `gtd doors` lists the doors of the workflows your `gtd.config.ts`
exports, plus any it adds. `gtd --workflow <name>` starts any workflow by name.

Each workflow is a factory — `feature({ testCommand: "npm run ci" })` — whose
options gtd validates when it loads the config; the pieces they are built from
are exported for your own workflows to reuse. See
[Using it in `gtd.config.ts`](./reference.md#using-it-in-gtdconfigts).

## The naive pass

After design the agent first implements the requirements directly,
breadth-first. It is asked to test the behaviour the criteria describe — one
test per behaviour, not per criterion, with no criterion ID in a test name —
through code that existed before the pass, but no test is required. The pass is
sent back while a test imports a file it added, or the suite is red on it. A
judge checks whether it changed anything outside the expected set (tests,
steering files; see `seamAllow`). Incidental changes land: the pass itself is
the implementation, with no rebuild, straight through the health loop and the
quality lap. A needed seam change resets: the pass is never applied. An agent
reads its whole diff and writes a refactor note (`.gtd/REFACTOR-NOTE.md`: which
seams, which shape); the seam is refactored first, flag-free with the existing
suite green, on its own with its own quality lap (`refactorQualityReviews`) and
review; then the feature is rebuilt on the refactored base, behind a release
flag, with the note and the naive diff as reference. The rebuild is asked to
carry over every test file the naive pass added or changed, and the suite must
be green; whether each criterion is still tested is the `criteria-coverage`
lens's call in the quality lap. A wrong approach is retried twice, then rests
for you to steer or overrule it. A refactor that already carried the whole
feature leaves the rebuild only the carried-over tests, and the feature's
quality lap and review cover the whole change. With `naiveTest` on (off by
default), you try every green naive pass by hand first, applied to the working
tree at `seam.try`, before the seam judge or anything builds on it: a clean
`gtd land` signs it off; notes in `.gtd/NAIVE-TEST.md`, code edits or a
requirements edit send it back to a new naive pass, which gets them, until you
sign off. See [The naive test](./reference.md#the-naive-test). Nothing else
tries the change by hand: the suite, the quality lap and the review check the
criteria. Feedback at the feature review re-runs design and the implementation,
never the naive pass; feedback at the refactor review re-runs the refactor,
never design; a refactor-review change the refactor cannot build is refused, and
the only way out is `gtd abandon`. A process from 27.5.0 or later whose judge
ruled `refactor-first` must `gtd abandon` too. Details in
[the naive-pass path](./reference.md#the-naive-pass-path).

**One process, one build.** A change is built in one pass — one naive pass, one
build, one quality lap, one review — however many criteria it has. Sizing the
work is yours: split a change too big for one process into several before the
sketch.

**Release flags (only when asked for).** A change ships unflagged unless its
requirements ask for a flag: a `## Release Flag` section in
`.gtd/REQUIREMENTS.md` reading `new` (a new release flag) or `existing: <NAME>`
(behind a flag that already exists). Triage writes it only when the sketch asks
for a flag; you can add, change or delete it at the design gate. With it, the
naive pass's judge runs as above and the build adds the new flag, or uses the
named one; without it, no seam judge or refactor runs and the naive pass lands
as the implementation, straight through the health loop and the quality lap. See
[Release flags](./reference.md#release-flags).

**Risk tier (flag `GTD_FLAG_RISK_TIER=1`, off by default).** Triage proposes a
risk tier, `low` or `high`, and the production signals to watch after merge.
Edit the first word under `## Risk Tier` at the design gate to change it; a
missing or unreadable tier means `high`. Each lap lands a
`Gtd-Mark: risk-tier=<low|high>` trailer and a `Gtd-Mark: production-signal=…`
trailer per signal; `gtd summary` reads the last lap's only. Its "needs a human
reviewer" line for `high` is advisory, not a gate.

## Rolling out and cleaning up release flags

Two more workflows retire a release flag. They are opt-in: the config
`gtd-wf config default` prints does not export them, so add `rollout` and
`cleanup` to its exports first. `gtd door rollout <flag>` turns it default-on,
`gtd door cleanup <flag>` removes it afterwards (`/gtd rollout <flag>` and
`/gtd cleanup <flag>` in Claude Code; `gtd --workflow rollout --var flag=<name>`
works too). See
[Rolling out and cleaning up a release flag](./reference.md#rolling-out-and-cleaning-up-a-release-flag).

Rollout makes "on under `GTD_FLAG_<NAME>=1`" prose wrong until cleanup, so once
the suite passes it lists every line outside the registry that names the flag
(as `path:line`, the first 50, then a `git grep` command over tracked files for
the rest) and edits none of them, leaving no file behind. The squash carries the
list only through the closing message `gtd summary` writes; the `Gtd-Mark:`
trailers survive only in the process history ref `refs/gtd/history/<entry>`,
recovered with `gtd history fetch | sh` and read with
`git log --format=%B <ref>`. An empty list says so in one line. Fix the prose by
hand or leave it for cleanup.

The delivery model these workflows implement: [Delivery model](./delivery.md).
