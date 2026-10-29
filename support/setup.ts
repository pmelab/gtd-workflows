// Every scenario's config can import the workflow under test as `#workflow`.
import { Before } from "quickpickle"
import type { TestkitWorld } from "@pmelab/gtd/testkit/gherkin"
import { workflowModules } from "./workflow.ts"

Before(async (world: TestkitWorld) => {
  for (const [specifier, module] of Object.entries(await workflowModules()))
    world.importable(specifier, module)
})
