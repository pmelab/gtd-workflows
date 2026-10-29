import { Given } from "quickpickle"
import type { TestkitWorld } from "@pmelab/gtd/testkit/gherkin"
import { CONFIG_SCAFFOLD } from "@support/workflow"

Given("the shipped workflows, as gtd install scaffolds them", (world: TestkitWorld) => {
  world.configure(CONFIG_SCAFFOLD)
})
