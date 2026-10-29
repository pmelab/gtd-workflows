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

## Writing a workflow

```sh
git clone https://github.com/pmelab/gtd-workflows && cd gtd-workflows
npm install
bin/gtd-wf new mine --from default   # or start an empty directory
```

A workflow is a directory with an `index.ts` exporting what a `gtd.config.ts`
exports: workflow functions or factories, and the reserved exports (`defaults`,
`summary`, `steering`, …). It imports gtd only through its public subpaths —
`@pmelab/gtd/flows`, `/wire`, `/steering`, `/workflow-kit`. See gtd's
[configuration](https://github.com/pmelab/gtd/blob/main/docs/configuration.md)
for the shape.

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

Tests import the testkit through `@support/testkit`, which resolves `#workflow`
in a config given as source.
