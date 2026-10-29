// The bundle entry (`dist/default.mjs`) a repository's `gtd.config.ts` imports.
import { feature } from "./feature/feature.js"

export { threads, type ThreadInfo } from "@pmelab/gtd/flows"
export { workflowOptions } from "./shared/workflow-options.js"
export { FlagOptions, ShippedOptions } from "./shared/options.js"
export { agentWithSkills, type ReviewRange } from "./shared/text.js"
export * from "./shared/steps.js"
export * from "./shared/health.js"
export {
  closeReview,
  handOffReview,
  handOffTail,
  qualityLap,
  REVIEW_ORIG,
  tail,
  type TailOptions,
} from "./shared/tail.js"
export { type Finding, type LensReport } from "./shared/lenses.js"
export { lensEntriesOf, lensesOf, lensOf } from "@pmelab/gtd/workflow-kit"
export * from "./feature/steps.js"
export * from "./feature/criteria.js"
export * from "./feature/planning.js"
export * from "./feature/refactor.js"
export * from "./feature/seam.js"
export {
  buildTail,
  type BuildTailOptions,
  type FeedbackTarget,
  type ReviewOutcome,
} from "./shared/review.js"
export * from "./feature/feature.js"
export { review, reviewFlow } from "./review/review.js"
export { fix, fixFlow, fixReviewNotes } from "./fix/fix.js"
export { rollout, rolloutFlow } from "./rollout/rollout.js"
export { cleanup, cleanupFlow } from "./cleanup/cleanup.js"

export default feature
