// Registers the workflow under test — this vitest project's — for `#workflow`.
// In a hook, not at import: a test file's `vi.mock` must apply first.
import { existsSync, readdirSync } from "node:fs"
import { join } from "node:path"
import { beforeAll } from "vitest"
import { registry } from "./workflow.ts"

beforeAll(async () => {
  const root = process.env["GTD_WORKFLOW_ROOT"]
  if (root === undefined) throw new Error("GTD_WORKFLOW_ROOT is not set")
  registry().set("#workflow", await import(join(root, "index.ts")))
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const index = join(root, entry.name, "index.ts")
    if (entry.isDirectory() && existsSync(index))
      registry().set(`#workflow/${entry.name}`, await import(index))
  }
})
