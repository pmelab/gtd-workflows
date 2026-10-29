// The gherkin world, with `a gtd config with:` reading the workflow under test.
import { setWorldConstructor } from "quickpickle"
import { TestkitWorld } from "@pmelab/gtd/testkit/gherkin"
import type { WorkflowModule } from "@pmelab/gtd/testkit"
import { resolveWorkflow } from "./workflow.ts"

class WorkflowWorld extends TestkitWorld {
  override configure(config: WorkflowModule): void {
    super.configure(typeof config === "string" ? resolveWorkflow(config) : config)
  }

  override extendConfig(tail: string): void {
    super.extendConfig(resolveWorkflow(tail))
  }
}

setWorldConstructor(WorkflowWorld)
