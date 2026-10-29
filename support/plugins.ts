import { mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { join, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import type { Plugin } from "vitest/config"

// gtd's own sources import these as text, as its bundler does.
export const rawText = (): Plugin => ({
  name: "raw-text",
  transform(_code, id) {
    if (/\.(md|yaml|html)$/.test(id)) {
      return { code: `export default ${JSON.stringify(readFileSync(id, "utf8"))};`, map: null }
    }
  },
})

// A git a test spawns must not read the developer's ~/.gitconfig: a signing
// setup there blocks every commit on a prompt nobody answers.
export const isolateGitConfig = (): void => {
  const cache = resolve(import.meta.dirname, "..", "node_modules", ".cache")
  mkdirSync(cache, { recursive: true })
  const path = resolve(cache, "gtd-test-gitconfig")
  writeFileSync(
    path,
    "[user]\n\tname = gtd test\n\temail = test@gtd.invalid\n[init]\n\tdefaultBranch = main\n[commit]\n\tgpgsign = false\n[tag]\n\tgpgsign = false\n",
  )
  process.env["GIT_CONFIG_GLOBAL"] = path
  process.env["GIT_CONFIG_NOSYSTEM"] = "1"
}

// gtd serves `@pmelab/gtd/workflows` to every config from its own sources.
// Here those sources are the workflow under test, so a test's config imports
// it exactly as a repository imports gtd's — and natively, not re-transpiled
// on every beat as a config's own files are.
export const servedAsShipped = (gtdWorkflows: string, workflow: string): Plugin => ({
  name: "served-as-shipped",
  enforce: "pre",
  resolveId(source) {
    const path = source.startsWith("file://") ? fileURLToPath(source) : source
    if (path.startsWith(`${gtdWorkflows}/`)) return join(workflow, path.slice(gtdWorkflows.length))
  },
})
