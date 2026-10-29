import { globSync, readdirSync } from "node:fs"
import { resolve } from "node:path"
import { quickpickle } from "quickpickle"
import { defineConfig } from "vitest/config"

const alias = [
  { find: /^@support\/(.+)$/, replacement: `${resolve("support")}/$1.ts` },
]

// One project per workflow: each registers its own steps, and two copies of
// one workflow would register the same step twice.
const workflows = readdirSync("workflows", { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)

export default defineConfig({
  resolve: { alias },
  test: {
    projects: workflows.map((name) => ({
      resolve: { alias },
      plugins: [quickpickle({ stepTimeout: 30_000, skipTags: ["@skip"] })],
      test: {
        name,
        include: [`workflows/${name}/**/*.test.ts`, `workflows/${name}/**/*.feature`],
        env: { GTD_WORKFLOW_ROOT: resolve("workflows", name) },
        setupFiles: [
          "./support/setup.ts",
          "@pmelab/gtd/testkit/gherkin",
          "./support/world.ts",
          ...globSync(`workflows/${name}/**/*.steps.ts`)
            .sort()
            .map((path) => `./${path}`),
        ],
        testTimeout: 120_000,
      },
    })),
  },
})
