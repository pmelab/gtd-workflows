// How gtd folds a step's own paths into its scope's access, mirrored from gtd
// (where it is not part of the package): each restricted side gets the
// steering file, then the code threads waiting on the agent; an unrestricted
// side stays `null`.
import type { AccessDef, ScopeAccess } from "@pmelab/gtd/flows"

const withExtras = (
  globs: readonly string[] | undefined,
  extras: readonly string[],
): readonly string[] | null => (globs === undefined ? null : [...new Set([...globs, ...extras])])

export const foldAccess = (
  scopeAccess: ScopeAccess | undefined,
  file: string | undefined,
  threadPaths: readonly string[],
): AccessDef => {
  const access = scopeAccess ?? {}
  const extras = [...(file === undefined ? [] : [file]), ...threadPaths]
  return { read: withExtras(access.read, extras), write: withExtras(access.write, extras) }
}
