import { Schema } from "effect"
import {
  defineWorkflow,
  type Flow,
  type WorkflowBase,
  type WorkflowBuild,
  type WorkflowDoors,
  type WorkflowFactory,
  refuse,
  settings,
} from "@pmelab/gtd/flows"
import { access } from "./access.js"
import { steering, summary } from "./workflow-options.js"
import { skills } from "./skills.js"
import { defaultFlagRegistry, defaults, envDefaults } from "./vars.js"

const setting = Schema.optionalWith(Schema.String, { exact: true })

export const ShippedOptions = Schema.Struct({
  reviewBase: setting,
  judgeBudgetBytes: setting,
  judgeIdenticalMinP: setting,
  reviewNoteActionable: setting,
  reviewSeverityMinP: setting,
  qualityTriageMinP: setting,
  criteriaQualityMinP: setting,
  standardMinP: setting,
  refactorFlagPattern: setting,
  seamAllow: setting,
  qualityReviews: setting,
  refactorQualityReviews: setting,
  testCommand: setting,
  plannerModel: setting,
  coderModel: setting,
  naiveTest: Schema.optionalWith(Schema.Boolean, { exact: true }),
})

export type ShippedOptions = Schema.Schema.Encoded<typeof ShippedOptions>

const over = (
  base: Readonly<Record<string, string>>,
  options: Readonly<Record<string, string | boolean>>,
): Record<string, string> => ({
  ...base,
  ...Object.fromEntries(
    Object.entries(options)
      .filter(([name]) => Object.hasOwn(base, name))
      .map(([name, value]) => [name, String(value)]),
  ),
})

/** The `naiveTest` setting, pinned at process start. Anything but true/false fails rather than guess. */
export const naiveTestOn = (): boolean => {
  const value = settings.naiveTest ?? defaults.naiveTest!
  if (value !== "true" && value !== "false")
    refuse(`gtd: naiveTest must be "true" or "false", got ${JSON.stringify(value)}`)
  return value === "true"
}

// Carried by every shipped workflow's build, so `export default feature()` is a whole config.
const reserved = { skills, access, steering, summary }

const schemaOf = <A, I>(options: Schema.Schema<A, I>) =>
  Schema.standardSchemaV1(options, { onExcessProperty: "error", errors: "all" })

/** A shipped flow's build: its options override the settings it declares, each in its own kind. */
export const shippedBuild =
  (flow: Flow, doors?: WorkflowDoors, base?: WorkflowBase) =>
  (options: ShippedOptions): WorkflowBuild => ({
    ...reserved,
    flow,
    defaults: over(defaults, options),
    envDefaults: over(envDefaults, options),
    doors,
    base,
  })

/** A shipped flow as a factory. */
export const shipped = (
  flow: Flow,
  doors?: WorkflowDoors,
  base?: WorkflowBase,
): WorkflowFactory<ShippedOptions> =>
  defineWorkflow(schemaOf(ShippedOptions), shippedBuild(flow, doors, base))

export const FlagOptions = Schema.Struct({ ...ShippedOptions.fields, flagRegistry: setting })

export type FlagOptions = Schema.Schema.Encoded<typeof FlagOptions>

/** A flag workflow's build: `flag` and `flagRegistry` are process settings, and its one door takes the flag. */
export const flagBuild =
  (flow: Flow, name: "rollout" | "cleanup") =>
  (options: FlagOptions): WorkflowBuild => ({
    ...reserved,
    flow,
    defaults: over({ ...defaults, flag: "", flagRegistry: defaultFlagRegistry }, options),
    envDefaults: over(envDefaults, options),
    doors: { [name]: { args: [{ name: "flag" }], vars: ({ flag }) => ({ flag: flag ?? "" }) } },
    base: undefined,
  })

export const flagShipped = (
  flow: Flow,
  name: "rollout" | "cleanup",
): WorkflowFactory<FlagOptions> => defineWorkflow(schemaOf(FlagOptions), flagBuild(flow, name))
