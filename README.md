# gtd workflows

Workflows for [gtd](https://github.com/pmelab/gtd). gtd itself ships none: a
repository's `gtd.config.ts` imports the workflows it runs, from here or from
anywhere else. Every directory under `workflows/` is one self-contained
workflow; `default` is the feature → review → fix workflow gtd used to bundle.

## Using a workflow

Workflows are used from a pinned checkout of this repository on your machine,
`~/.local/share/gtd/workflows` (override with `$GTD_WF_PINNED`):

```sh
git clone https://github.com/pmelab/gtd-workflows ~/.local/share/gtd/workflows
~/.local/share/gtd/workflows/bin/gtd-wf pin origin/main   # or a tag
~/.local/share/gtd/workflows/bin/gtd-wf config default > gtd.config.ts
```

`pin` checks the ref out, installs the runtime dependencies (`effect`,
`esbuild`) and bundles each workflow into `dist/<name>.mjs`. `config` prints a
`gtd.config.ts` importing that bundle by its absolute path — so the config works
on machines with the checkout at the same path, and every other machine needs
its own checkout and its own config.

gtd itself is never installed in the checkout: the running gtd serves every
`@pmelab/gtd/*` import.

- **Pin only while no gtd process is mid-run** in a repository using the pin: a
  process resting at a step the new pin no longer has breaks. gtd warns when a
  config file changes mid-run.
- **A workflow is written against a gtd version.**
  `workflows/<name>/EJECTED.json` names it; `gtd-wf status` shows it beside the
  gtd on `PATH`.

## The default workflow

`default` is the feature → review → fix workflow gtd used to bundle, plus
`rollout` and `cleanup` for release flags.

- [The guide](docs/default.md) — what you do at each moment of a process
- [Reference](docs/reference.md) — every step, refusal and setting, and how to
  reuse its parts in your own `gtd.config.ts`
- [Setup](docs/setup.md) — the skills its prompts name, and how to swap them
- [Delivery model](docs/delivery.md) — trunk-based delivery behind release
  flags, and where it puts human gates
- [Glossary](CONTEXT.md) — the words it adds to gtd's

`evals/` holds the workflow's prompt evals, copied verbatim from gtd; they are
not yet wired to this repository. See [Prompt evals](docs/evals.md).

## Writing a workflow

```sh
git clone https://github.com/pmelab/gtd-workflows && cd gtd-workflows
npm install
bin/gtd-wf new mine --from default   # or start an empty directory
```

A workflow is a directory with an `index.ts` exporting its workflow factories
and the parts a `gtd.config.ts` composes into flows of its own. A factory's
build carries its own settings, skills, access, steering files and summary, so
`export default feature()` alone is a whole config; a config's own flow gets the
same through gtd's `workflow(flow, options)` (the `default` workflow exports
them as `workflowOptions`). It exports none of the file-level names gtd no
longer reads — `defaults`, `envDefaults`, `summary`, `base`, `steering`,
`skills`, `access`, `doors` — since a config re-exporting one fails to load. It
imports gtd only through its public subpaths — `@pmelab/gtd/flows`, `/wire`,
`/steering`, `/workflow-kit` — and avoids their `@deprecated` names. See gtd's
[configuration](https://github.com/pmelab/gtd/blob/main/docs/configuration.md)
and
[workflow kit](https://github.com/pmelab/gtd/blob/main/docs/workflow-kit.md).

To try changes, commit them and pin the working copy's commit:

```sh
git commit -am "feat(mine): …"
bin/gtd-wf pin        # HEAD of this working copy
bin/gtd-wf status
```

`gtd-wf pin <ref>` moves back to any earlier commit.

## Testing

```sh
npm test                        # every workflow
npx vitest run --project mine   # one workflow
npm run typecheck
```

Tests use gtd's
[testkit](https://github.com/pmelab/gtd/blob/main/docs/testing.md), installed as
a dev dependency: they drive gtd's real engine in memory against the workflow.
Each workflow is its own vitest project — its `*.test.ts`, its `.feature` files
and its `*.steps.ts` — so two workflows never share steps.

Drives are strict: a scenario scripts a step only once a drive reaches it, and a
drive meant to rest at a check step says so (`the process is driven leniently`,
or `{ strict: false }` in code).

A test configures the workflow under test with `#workflow` (and
`#workflow/feature`, `#workflow/review` … for its subdirectories), which
resolves to the workflow directory the test lives in. A copy made with
`gtd-wf new` tests itself without edits:

```gherkin
Given a gtd config with:
  """
  import { feature } from "#workflow/feature"
  export default feature({ naiveTest: true })
  """
```

Tests import the testkit through `@support/testkit`, whose `testRepo` passes the
workflow under test to gtd's as `modules`; scenarios get the same through
`world.importable()` in a `Before` hook. Steps the scenarios need beyond gtd's
own live in the workflow's `*.steps.ts`; one gtd also registers is an ambiguous
step, which quickpickle rejects — delete the copy.
