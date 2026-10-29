// The workflow under test — this vitest project's — keyed by the specifiers a
// test's config imports it as: `#workflow`, and `#workflow/<dir>` for each
// subdirectory with an `index.ts`. Imported on first use, never at load: a test
// file's `vi.mock` must apply first.
import { existsSync, readdirSync } from "node:fs"
import { join } from "node:path"

/** What a repository's `gtd.config.ts` holds to run every workflow this one ships. */
export const CONFIG_SCAFFOLD = `export { feature as default, feature } from "#workflow/feature"
export { review } from "#workflow/review"
export { fix } from "#workflow/fix"
`

type Modules = Record<string, Readonly<Record<string, unknown>>>

const load = async (): Promise<Modules> => {
  const root = process.env["GTD_WORKFLOW_ROOT"]
  if (root === undefined) throw new Error("GTD_WORKFLOW_ROOT is not set")
  const modules: Modules = { "#workflow": await import(join(root, "index.ts")) }
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const index = join(root, entry.name, "index.ts")
    if (entry.isDirectory() && existsSync(index))
      modules[`#workflow/${entry.name}`] = await import(index)
  }
  return modules
}

let loaded: Promise<Modules> | undefined

export const workflowModules = (): Promise<Modules> => (loaded ??= load())
