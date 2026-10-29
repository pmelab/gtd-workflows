import type { Summary, WorkflowOptions } from "@pmelab/gtd/flows"
import { access } from "./access.js"
import { skills } from "./skills.js"
import * as t from "./text.js"
import { REQUIREMENTS, REVIEW } from "./steps.js"
import { defaults, envDefaults } from "./vars.js"

export const summary: Summary = t.summaryPrompt

export const steering = { [REQUIREMENTS]: "qa", [REVIEW]: "review" }

/** What every shipped workflow carries, for `workflow(flow, workflowOptions)` around a flow of your own. */
export const workflowOptions = {
  defaults,
  envDefaults,
  summary,
  steering,
  skills,
  access,
} satisfies WorkflowOptions
