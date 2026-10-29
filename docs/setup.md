# Setup: the skills the default workflow names

## Prerequisites

Install all three skill sources the `default` workflow names in its prompts —
none is optional, all three are hard prerequisites:

- [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills)
- the ponytail skills from
  [`DietrichGebert/ponytail`](https://github.com/DietrichGebert/ponytail) —
  install only `--skill ponytail --skill ponytail-review`
- joshmanders' `test-audit`, from
  [`joshmanders/dotfiles`](https://github.com/joshmanders/dotfiles) — install
  with `npx -y skills add joshmanders/dotfiles --skill test-audit`

The workflow's build/fix/review scopes name skills from these sets in their
prompts instead of spelling out their technique in prose. Without a source
installed, your harness has nothing to load at the steps that name it, and the
prompt carries no prose standing in for it. Neither gtd nor the workflow
installs, resolves, or verifies any of this — a repo can also repoint any
scope's configured skill list (`config.skills` in `gtd.config.ts`, see below) to
name a different set its own harness has instead, or set it to `[]` to drop the
skill names from that scope.

**Install the skills, never the ponytail plugin** — its hooks inject into every
turn and bypass the per-scope `skills` entries above.

A name missing from a scope's configured list is skipped silently and costs
nothing. A missing `qualityReviews` entry does not share that rule — see
[Extending the quality-review lap](#extending-the-quality-review-lap) below. Two
of the default lenses (`ponytail-review`, `test-audit`) come from sources a
reader has no reason to already have, so the default configuration wastes turns
per quality lap until they are installed. `correctness` needs
`code-review-and-quality` (already in `addyosmani/agent-skills`); `conventions`,
`spec-challenge` and `criteria-coverage` need no skill.

### Using a different skill set

Every scope of the workflow that runs agent turns has its own addressable full
name, and a driver that can restrict a turn's skills passes that scope's list —
see [the reference](./reference.md#skills-and-access) for the full list and
gtd's
[Skills](https://github.com/pmelab/gtd/blob/main/docs/configuration.md#skills)
for the validation rules. Two routes, and they combine:

- **Instead of the bundled set** — repoint the scope's `config.skills` entry. It
  also feeds the `skills` key on `gtd next --json` at that scope's turns — a
  driver that reads it can preload the same names (see
  [Writing your own driver](https://github.com/pmelab/gtd/blob/main/docs/driver.md#writing-your-own-driver)):

  ```ts
  // gtd.config.ts — implement loads your own skill instead of the bundled pair
  export const config = defineConfig({
    skills: { implement: ["my-org-tdd-skill"] },
  })
  ```

- **In addition to the bundled set** — there is no append mechanism: an entry
  REPLACES the scope's bundled list, it never adds to it. Wanting the bundled
  skills plus your own means writing the whole list — bundled names included —
  into your own value:

  ```ts
  // gtd.config.ts — keep the bundled pair, add one more
  export const config = defineConfig({
    skills: {
      implement: [
        "test-driven-development",
        "incremental-implementation",
        "my-org-tdd-skill",
      ],
    },
  })
  ```

  The cost of this route: a later release of this workflow that changes
  `implement`'s default is silently lost to you, because your override already
  replaced it — you keep whatever list you wrote until you edit it again.

Both routes share the same safety rules:

- A skill name your harness does not have is skipped silently by the preamble.
  An over-long list costs nothing.
- A skill carrying `disable-model-invocation: true` is skipped just as silently
  — the agent cannot load it at all, only a human can, by slash command. Naming
  one in `skills` is a no-op with no error. This is the trap most likely to bite
  when picking your own set: check the skill's frontmatter before relying on it
  here.

### Extending the quality-review lap

`qualityReviews` (default
`correctness, owasp-security, ponytail-review, test-audit, conventions, spec-challenge, criteria-coverage`)
is a skill set too, but a different shape from a scope's `skills` entry above:
each entry is its own full turn and its own scope, not a list handed to one
scope. Extend it for a project-specific concern — a company security checklist,
a house style skill — the same way as any other setting, as a factory option. A
lens added here does not reach the refactor review; that takes
`refactorQualityReviews` too:

```ts
// gtd.config.ts — keep the bundled seven, add a company checklist
export default feature({
  qualityReviews:
    "correctness, owasp-security, ponytail-review, test-audit, conventions, spec-challenge, criteria-coverage, acme-security-checklist",
})
```

or, highest precedence, via the matching `GTD_<NAME>` environment variable:

```bash
GTD_QUALITYREVIEWS="correctness, owasp-security, ponytail-review, test-audit, conventions, spec-challenge, criteria-coverage, acme-security-checklist" gtd next
```

Unlike a scope's `skills` entry, the workflow DOES split this one — on every
comma, one lens per entry — because each entry is its own turn rather than one
step's skill list. Keep entries free of commas and of characters that don't
belong in a filename: each trimmed entry becomes part of a queued review file's
name. The built-in names `correctness`, `conventions`, `spec-challenge` and
`criteria-coverage` are lenses the workflow defines itself — a brief rides in
the prompt, no skill needed — and are exempt from the warning below; a user
skill of the same name is shadowed. For any other name, it does NOT share
`skills`'s "costs nothing" rule for a name your harness lacks: `reviewing` still
burns its own full turn with no lens loaded, since the queue file exists whether
or not anything can load it — a typo costs a whole turn, silently. Blanking the
whole var, in contrast, does switch the lap off outright.

An entry may name the model its turn runs on, `<lens>=<model>` —
`"correctness=smart, conventions=smart"` runs `conventions` on the planner's
hint instead of its default `base`. See [the reference](./reference.md#settings)
for each lens's default.

`qualityReviews` and `config.skills` keys `build.quality.<lens>` are a pair, not
alternatives: `qualityReviews` decides how many turns the lap runs (one per
lens, in order), and each lens is its own scope, so its own skills. By default a
lens scope's skills ARE the lens; a `build.quality.<lens>` entry REPLACES them
with the configured list — the prompt body still names which lens the turn is
for, but that lens no longer loads as a skill once overridden. The key is valid
only while the lens is listed in `qualityReviews`. The refactor review's lenses
are the same pair under `refactorQualityReviews` and
`refactor.build.quality.<lens>`; a lens added to `qualityReviews` does not reach
it. See [the reference](./reference.md#settings) for the cost of extending it.
