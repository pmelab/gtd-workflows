import { globSync, readdirSync, readFileSync } from "node:fs"
import { resolve } from "node:path"
import { quickpickle } from "quickpickle"
import { defineConfig, type Plugin } from "vitest/config"

// The gtd internals a few tests reach (`@gtd/<unit>`) are its sources, which
// import markdown as text the way its bundler does.
const rawText = (): Plugin => ({
  name: "raw-text",
  transform(_code, id) {
    if (/\.(md|yaml|html)$/.test(id)) {
      return { code: `export default ${JSON.stringify(readFileSync(id, "utf8"))};`, map: null }
    }
  },
})

const alias = [
  { find: /^@gtd\//, replacement: `${resolve("node_modules/@pmelab/gtd/src")}/` },
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
      plugins: [rawText(), quickpickle({ stepTimeout: 30_000, skipTags: ["@skip"] })],
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
