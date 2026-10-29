// A config a test writes imports the workflow under test as `#workflow` (or
// `#workflow/feature` …). gtd evaluates that config in memory, where nothing
// resolves `#workflow`, and transpiling the workflow from disk on every beat is
// slow. So the setup file imports the workflow once, natively, into a registry,
// and each `#workflow` import is rewritten to read it from there.
const REGISTRY = Symbol.for("gtd-workflows:modules")
type Registry = Map<string, Readonly<Record<string, unknown>>>

export const registry = (): Registry => {
  const global = globalThis as { [REGISTRY]?: Registry }
  return (global[REGISTRY] ??= new Map())
}

const lookup = (specifier: string): string =>
  `globalThis[Symbol.for(${JSON.stringify(REGISTRY.description)})].get(${JSON.stringify(specifier)})`

const names = (list: string): (readonly [string, string])[] =>
  list
    .split(",")
    .map((entry) => entry.trim())
    .filter((entry) => entry !== "")
    .map((entry) => {
      const [name, alias] = entry.split(/\s+as\s+/)
      return [name!, alias ?? name!] as const
    })

let rewritten = 0

/** `source` with every `import { … }` and `export { … }` of `#workflow…` reading the registry. */
export const resolveWorkflow = (source: string): string =>
  source.replace(
    /\b(import|export)\s*\{([^}]*)\}\s*from\s*(["'])(#workflow(?:\/[\w-]+)?)\3/g,
    (_, kind: string, list: string, __: string, specifier: string) => {
      if (!registry().has(specifier)) throw new Error(`#workflow: no module "${specifier}"`)
      const module = `__workflow${++rewritten}`
      const bindings = names(list)
      const lines = [`const ${module} = ${lookup(specifier)}`]
      for (const [name, alias] of bindings) {
        if (kind === "import") lines.push(`const ${alias} = ${module}[${JSON.stringify(name)}]`)
        else if (alias === "default")
          lines.push(`export default ${module}[${JSON.stringify(name)}]`)
        else lines.push(`export const ${alias} = ${module}[${JSON.stringify(name)}]`)
      }
      return lines.join("\n")
    },
  )
