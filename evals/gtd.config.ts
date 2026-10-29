// The prompt evals' workflows: `gtd start <name>` runs one bundled agent
// step, with the bundled prompt and persona, against the fixture's tree.
// `evals/fixture.mjs` copies it into each fixture repo.
// It imports this repository's bundle (`npm run build`); the fixture rewrites
// the relative specifier to its absolute path.
import { read, scope, start, workflow } from "@pmelab/gtd/flows"
import { collecting, fixCheck, reviewing, triage, workflowOptions } from "../dist/default.mjs"

export { feature as default } from "../dist/default.mjs"

// One workflow per bundled agent step, named by the step's full name in
// camelCase (`build.review.reviewing` -> `buildReviewReviewing`): each runs
// that step in the scope the workflow gives it, with the shipped workflow's
// settings, skills and access. Steps that review since a
// base see the process's own diff base; collecting reads its capture from
// `.gtd/REVIEW_RAW.md`, where an eval fixture puts it. `evals/fixture.mjs`
// derives the name from the case's `state`.
export const buildReviewReviewing = workflow(
  () => scope("build", () => reviewing(start())),
  workflowOptions,
)
export const buildReviewCollecting = workflow(
  () => scope("build", () => collecting(read(".gtd/REVIEW_RAW.md") ?? "")),
  workflowOptions,
)
export const designTriage = workflow(() => scope("design", () => triage(start())), workflowOptions)
export const buildFix = workflow(() => scope("build", () => fixCheck()), workflowOptions)
