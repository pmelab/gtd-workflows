// The public testkit, with a config's `#workflow` imports reading the workflow under test.
import { testRepo as gtdTestRepo } from "@pmelab/gtd/testkit"
import { resolveWorkflow } from "./workflow.ts"

export * from "@pmelab/gtd/testkit"
export type { TestkitWorld } from "@pmelab/gtd/testkit/gherkin"

/** What a repository's `gtd.config.ts` holds to run every workflow this one ships. */
export const CONFIG_SCAFFOLD = `export {
  feature as default,
  feature,
  defaults,
  envDefaults,
  summary,
  steering,
  skills,
  access,
} from "#workflow/feature"
export { review } from "#workflow/review"
export { fix } from "#workflow/fix"
`

export const testRepo: typeof gtdTestRepo = (options) =>
  gtdTestRepo(
    typeof options.workflow === "string"
      ? { ...options, workflow: resolveWorkflow(options.workflow) }
      : options,
  )
