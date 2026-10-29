// The public testkit, with a config's `#workflow` imports reading the workflow under test.
import { testRepo as gtdTestRepo } from "@pmelab/gtd/testkit"
import { workflowModules } from "./workflow.ts"

export { CONFIG_SCAFFOLD } from "./workflow.ts"

export * from "@pmelab/gtd/testkit"

const modules = await workflowModules()

export const testRepo: typeof gtdTestRepo = (options) =>
  gtdTestRepo({ ...options, modules: { ...modules, ...options.modules } })
