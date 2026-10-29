// What the jev judge provider makes of a question's criteria, mirrored from
// gtd (whose judges are not part of its package): a question it cannot split
// into labelled options is one it cannot send.
const LABEL = /(?:^|\. )([A-Za-z][A-Za-z0-9_-]*): /g

const splitLabels = (criteria: string): [string, string][] => {
  const hits = [...criteria.matchAll(LABEL)]
  return hits.map((m, i) => {
    const start = m.index + m[0].length
    const end = hits[i + 1]?.index ?? criteria.length
    return [m[1] as string, criteria.slice(start, end).replace(/^ /, "")]
  })
}

interface Question {
  readonly id: string
  readonly primitive: string
  readonly criteria: string
}

export const toRequest = (
  questions: readonly Question[],
  _state: Readonly<Record<string, string>>,
): { questions: Record<string, { criteria: object }> } => ({
  questions: Object.fromEntries(
    questions.map((q) => [q.id, { criteria: Object.fromEntries(splitLabels(q.criteria)) }]),
  ),
})
