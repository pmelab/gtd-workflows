import { globSync, readdirSync, realpathSync } from "node:fs"
import { resolve } from "node:path"
import { quickpickle } from "quickpickle"
import { defaultServerConditions } from "vite"
import { defineConfig } from "vitest/config"
import { isolateGitConfig, rawText, servedAsShipped } from "./support/plugins.ts"

const GTD = realpathSync("node_modules/@pmelab/gtd")

isolateGitConfig()

const resolveConfig = {
  alias: [{ find: /^@gtd\//, replacement: `${GTD}/src/` }],
  // gtd's sources, not its build: the engine the testkit runs and the
  // `@pmelab/gtd/flows` a workflow imports must be one module.
  conditions: ["source", ...defaultServerConditions],
  // gtd's testkit registers its steps with the same quickpickle the features run on.
  dedupe: ["quickpickle", "vitest", "effect"],
}

// One project per workflow: each brings its own steps, two copies of one
// workflow would register the same step twice, and each project serves its
// own workflow as `@pmelab/gtd/workflows`.
const workflows = readdirSync("workflows", { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)

export default defineConfig({
  resolve: resolveConfig,
  ssr: { resolve: { conditions: resolveConfig.conditions } },
  test: {
    projects: workflows.map((name) => ({
      resolve: resolveConfig,
      ssr: { resolve: { conditions: resolveConfig.conditions } },
      plugins: [
        servedAsShipped(`${GTD}/src/workflows`, resolve("workflows", name)),
        rawText(),
        quickpickle({ stepTimeout: 30_000, skipTags: ["@skip"] }),
      ],
      test: {
        name,
        include: [`workflows/${name}/**/*.test.ts`, `workflows/${name}/**/*.feature`],
        setupFiles: [
          `${GTD}/src/testkit/steps.ts`,
          ...globSync(`workflows/${name}/**/*.steps.ts`)
            .sort()
            .map((path) => `./${path}`),
        ],
        testTimeout: 120_000,
      },
    })),
  },
})
