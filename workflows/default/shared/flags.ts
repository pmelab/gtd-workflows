/** This workflow's release flags, each read from `GTD_FLAG_<NAME>` as `flag_<name>`. */
export interface FlagDeclaration {
  readonly name: string
  readonly defaultOn?: boolean
}

export const FLAGS: readonly FlagDeclaration[] = [{ name: "risk_tier" }]
