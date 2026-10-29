# gtd workflows

My own gtd workflows, each ejected from gtd's shipped ones and changed from
there. Every directory under `workflows/` is one self-contained workflow
(`default`, and later e.g. `simple`, `complex` or `blog`), exporting the same
factories gtd's `@pmelab/gtd/workflows` does.

## Setup

```sh
npm install        # links ../gtd (the gtd checkout) as @pmelab/gtd
ln -s "$PWD/bin/gtd-wf" ~/.dotfiles/bin/gtd-wf   # or put bin/ on PATH
```

The gtd checkout at `../gtd` must be built (`npm run build` there): the tests
run gtd's engine from its sources, which import the built web client.

## Commands

```sh
gtd-wf eject <name> [--gtd <path>]  # copy gtd's shipped workflows into workflows/<name>
gtd-wf new <name> --from <name>     # start a workflow as a copy of another
gtd-wf pin [ref]                    # check out ref (default HEAD) in the pinned checkout
gtd-wf status                       # the pin, its workflows, the gtd they were ejected from
gtd-wf config <name>                # print a gtd.config.ts using the pinned workflow
```

`eject` rewrites the copy's imports: gtd's public units become
`@pmelab/gtd/<unit>` (served by the running gtd at runtime), and the internals
only tests use become `@gtd/<unit>`, aliased to the linked gtd's sources. It
records the gtd version and commit in `workflows/<name>/EJECTED.json`.

## Using a workflow

Repositories never import from this working copy. They import from a separate
checkout of this repository, pinned at a commit: `~/.config/gtd/pinned`
(override with `$GTD_WF_PINNED`).

```sh
git commit -am "feat(simple): …"
gtd-wf pin            # pin the commit just made
gtd-wf config simple > ~/Code/some-repo/gtd.config.ts
```

Editing here changes nothing a running process sees until the next `pin`.
`gtd-wf pin <ref>` moves back to any earlier commit.

- **Pin only while no gtd process is mid-run** on a repository using the pin: a
  process resting at a step the new pin no longer has breaks. gtd warns when a
  config file changes mid-run.
- **A workflow is tied to the gtd it was ejected from.** Upgrading gtd can break
  it; run the tests after every gtd upgrade (`EJECTED.json` says which version
  it started from).
- The pinned checkout installs only runtime dependencies (`effect`). gtd itself
  is never installed there: the running gtd serves every `@pmelab/gtd/*` import.

## Testing

```sh
npm test                          # every workflow
npx vitest run --project simple   # one workflow
npm run typecheck
```

Each workflow is its own vitest project: its `*.test.ts` files, its `.feature`
files (quickpickle) and its `*.steps.ts`, on top of gtd's testkit steps. Tests
drive gtd's engine in memory against the workflow, the same way gtd tests its
shipped ones.

Inside a workflow's project, `@pmelab/gtd/workflows` (and `/feature`, `/review`
…) **is that workflow**: gtd serves it in place of its own shipped one. A test
config imports it exactly as a repository imports gtd's, so the ejected tests
stay word for word what gtd ships, and a copy made with `gtd-wf new` tests
itself without edits:

```gherkin
Given a gtd config with:
  """
  import { feature } from "@pmelab/gtd/workflows/feature"
  export default feature({ naiveTest: true })
  """
```
