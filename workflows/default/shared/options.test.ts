import { describe, expect, it } from "vitest"
import { FLAGS, type FlagDeclaration } from "./flags.js"
import { workflow } from "@pmelab/gtd/flows"
import { testRepo } from "@pmelab/gtd/testkit"
import * as workflows from "../index.js"
import { flagBuild, shippedBuild } from "./options.js"
import { skills } from "./skills.js"

const { feature, fix, review, ShippedOptions } = workflows
const { defaults, envDefaults } = workflows.workflowOptions
const flow = async (): Promise<void> => {}
const built = shippedBuild(flow)

/** What gtd prints when it loads a config whose default export is `workflow`. */
const loading = async (workflow: unknown): Promise<string> => {
  const { stderr } = await testRepo({ workflow: { default: workflow } }).gtd("next")
  return stderr
}

describe("the bundle entry", () => {
  it("loads re-exported whole, exporting none of the names gtd refuses", async () => {
    const repo = testRepo({ workflow: { ...workflows } })
    expect(await repo.next()).toMatchObject({ idle: true, state: "idle" })
  })

  it("lets a flow of a config's own carry the shipped options", async () => {
    const hotfix = workflow(async () => {
      await workflows.fixCheck()
    }, workflows.workflowOptions)
    const repo = testRepo({ workflow: { default: feature, hotfix } })
    await repo.start("hotfix")
    expect(repo.messages().at(-1)).toContain("Gtd-Var: qualityReviews=")
  })
})

describe("the shipped workflow factories", () => {
  it("take exactly the settings the shipped workflows declare as options", () => {
    expect(Object.keys(ShippedOptions.fields).sort()).toEqual(
      [...Object.keys(defaults), ...Object.keys(envDefaults)]
        .filter((name) => !name.startsWith("flag_"))
        .sort(),
    )
  })

  it("declare a flag_<name> default for exactly the registered flags", () => {
    const declared = Object.keys(defaults).filter((name) => name.startsWith("flag_"))
    expect(declared.sort()).toEqual(FLAGS.map(({ name }) => `flag_${name}`).sort())
    for (const { name, defaultOn } of FLAGS as readonly FlagDeclaration[])
      expect(defaults).toHaveProperty(`flag_${name}`, defaultOn ? "1" : "0")
  })

  it("declare a seamAllow default a factory option overrides", () => {
    expect(built({ seamAllow: "docs/**" }).defaults).toMatchObject({ seamAllow: "docs/**" })
  })

  it("refuse the removed flagMode option", async () => {
    expect(defaults.flagMode).toBeUndefined()
    expect(await loading(feature({ flagMode: false } as never))).toContain('option "flagMode"')
  })

  it("declare flag_risk_tier off by default; it is no factory option", () => {
    expect(Object.keys(ShippedOptions.fields)).not.toContain("flag_risk_tier")
  })

  it("lay each option over the shipped setting of its own kind", () => {
    expect(built({ qualityReviews: "correctness", testCommand: "npm run ci" })).toMatchObject({
      defaults: { ...defaults, qualityReviews: "correctness" },
      envDefaults: { ...envDefaults, testCommand: "npm run ci" },
    })
  })

  it("default reviewSeverityMinP to 0.7 and let a factory override win", () => {
    expect(defaults.reviewSeverityMinP).toBe("0.7")
    expect(built({ reviewSeverityMinP: "0.9" }).defaults).toMatchObject({
      reviewSeverityMinP: "0.9",
    })
  })

  it("default refactorFlagPattern to GTD_FLAG_ matches and let a factory override win", () => {
    expect(defaults.refactorFlagPattern).toBe("\\bGTD_FLAG_\\w+")
    expect(built({ refactorFlagPattern: "\\bFF_\\w+" }).defaults).toMatchObject({
      refactorFlagPattern: "\\bFF_\\w+",
    })
  })

  it("build seamAllow's default from the test-file globs, byte-equal to the shipped string", () => {
    expect(defaults.seamAllow).toBe(
      "**/*.test.*, **/*.spec.*, **/*.feature, **/tests/**, **/test/**, **/__tests__/**, .gtd/**",
    )
  })

  it("default refactorQualityReviews to the three refactor lenses and let a factory option win", () => {
    expect(defaults.refactorQualityReviews).toBe("correctness, ponytail-review, conventions")
    expect(built({ refactorQualityReviews: "correctness" }).defaults).toMatchObject({
      refactorQualityReviews: "correctness",
    })
    expect(flagBuild(flow, "rollout")({ refactorQualityReviews: "" }).defaults).toMatchObject({
      refactorQualityReviews: "",
    })
  })

  it("build the shipped settings unchanged with no options", () => {
    expect(built({})).toMatchObject({ defaults, envDefaults })
  })

  it("carry the skills, access, steering and summary, so a factory alone is a whole config", async () => {
    const build = built({})
    expect(build.skills).toBe(skills)
    expect(build).toMatchObject({
      steering: workflows.workflowOptions.steering,
      summary: workflows.workflowOptions.summary,
    })
    expect(typeof build.access).toBe("function")
    const repo = testRepo({ workflow: { default: feature() } })
    expect(await repo.next()).toMatchObject({ idle: true, state: "idle" })
  })

  it("reject a misspelled option, at the type level and at load, naming the known ones", async () => {
    // @ts-expect-error — `testComand` is no option
    expect(await loading(feature({ testComand: "npm test" }))).toMatch(
      /testComand: workflow "default" option "testComand": is unexpected, expected: .*"testCommand"/,
    )
  })

  it("reject a removed option at the type level and at load", async () => {
    // @ts-expect-error — `model` was never (or is no longer) an option
    expect(await loading(review({ model: "smart" }))).toContain('option "model": is unexpected')
  })

  it("reject a value of the wrong type at the type level and at load", async () => {
    // @ts-expect-error — settings are strings
    expect(await loading(fix({ judgeBudgetBytes: 65536 }))).toContain('option "judgeBudgetBytes"')
  })

  describe("flagShipped", () => {
    it("declare flag and flagRegistry as process settings, so --var flag= is accepted", () => {
      expect(flagBuild(flow, "rollout")({})).toMatchObject({
        defaults: { ...defaults, flag: "", flagRegistry: "src/flags/index.ts" },
        envDefaults,
      })
    })

    it.each(["rollout", "cleanup"] as const)(
      "%s declares one door named after it, with one required flag arg",
      async (name) => {
        const repo = testRepo({ workflow: { default: feature, [name]: workflows[name]() } })
        const { stdout } = await repo.gtd("start")
        expect(stdout).toContain(name)
        expect(stdout).toContain("<flag>")
      },
    )

    it.each(["rollout", "cleanup"] as const)("%s builds one door of that name", (name) => {
      const doors = flagBuild(flow, name)({}).doors
      expect(Object.keys(doors ?? {})).toEqual([name])
      expect(doors?.[name]?.args).toEqual([{ name: "flag" }])
      expect(doors?.[name]?.vars?.({ flag: "x" })).toEqual({ flag: "x" })
      expect(doors?.[name]?.vars?.({})).toEqual({ flag: "" })
    })

    it("fail the load on an unknown option", async () => {
      // @ts-expect-error — `flag` is a --var, not an option
      expect(await loading(workflows.rollout({ flag: "x" }))).toContain(
        'option "flag": is unexpected',
      )
    })
  })
})
