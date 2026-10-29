// The prompt evals' workflows: `gtd start <name>` runs one bundled agent
// step, with the bundled prompt and persona, against the fixture's tree.
// `evals/fixture.mjs` copies it into each fixture repo.
import { read, scope, start, workflow } from "@pmelab/gtd/flows"
import { collecting, fixCheck, reviewing, triage } from "@pmelab/gtd/workflows"

export { feature as default, defaults } from "@pmelab/gtd/workflows"

// One workflow per bundled agent step, named by the step's full name in
// camelCase (`build.review.reviewing` -> `buildReviewReviewing`): each runs
// that step in the scope the workflow gives it. Steps that review since a
// base see the process's own diff base; collecting reads its capture from
// `.gtd/REVIEW_RAW.md`, where an eval fixture puts it. `evals/fixture.mjs`
// derives the name from the case's `state`.
export const buildReviewReviewing = workflow(() => scope("build", () => reviewing(start())))
export const buildReviewCollecting = workflow(() =>
  scope("build", () => collecting(read(".gtd/REVIEW_RAW.md") ?? "")),
)
export const designTriage = workflow(() => scope("design", () => triage(start())))
export const buildFix = workflow(() => scope("build", () => fixCheck()))
