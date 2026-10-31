import {
  changes,
  hasThreadFor,
  requireAnswers,
  requireReplies,
  requireThreadsClosed,
  requireProgress,
  scope,
} from "@pmelab/gtd/flows"
import { REQUIREMENTS } from "../shared/steps.js"
import type { RejectedCriterion } from "../shared/text.js"
import { judgeCriteria, keepUnchanged, requireCriteria, requireImpact } from "./criteria.js"
import { requireReleaseFlag } from "./release-flag.js"
import { answerProductQuestions, triage } from "./steps.js"

/**
 * Always stop for the human. Resolves `true` when the round changed anything
 * (the author revises), `false` on a clean re-run. Open threads refuse every
 * landing; unticked questions only refuse a round with no thread for the
 * agent to answer.
 */
const noteGate = async (file: string, answer: () => Promise<void>): Promise<boolean> => {
  await answer()
  requireThreadsClosed(file)
  if (changes().length === 0) return false
  if (!hasThreadFor("agent", file)) requireAnswers(file)
  return true
}

/** Triage turns sent back to revise rejected criteria, per round. */
const RETRIES = 2

/** One triage round and its retries; resolves the criteria the judge still rejects. */
const triageRound = async (
  base: string,
  guard: (() => void) | undefined,
  kept: ReadonlySet<string>,
): Promise<readonly RejectedCriterion[]> => {
  let rejected: readonly RejectedCriterion[] = []
  for (let retry = 0; ; retry++) {
    await triage(base, rejected)
    // A retry may change nothing: the planner holds the judge wrong, and the human decides.
    if (retry > 0 && changes().length === 0) return rejected
    if (retry === 0) requireProgress(REQUIREMENTS)
    requireReplies(REQUIREMENTS)
    requireCriteria(REQUIREMENTS)
    requireImpact(REQUIREMENTS)
    requireReleaseFlag(REQUIREMENTS)
    guard?.()
    rejected = await judgeCriteria(REQUIREMENTS, kept)
    if (rejected.length === 0 || retry === RETRIES) return rejected
  }
}

/** Triage the sketch since `base` into requirements, until no product question is open; `guard` holds every round's criteria. */
export const design = (base: string, guard?: () => void): Promise<void> =>
  scope("design", async () => {
    // Flagged criteria the human kept at a gate: never judged again in this design.
    const kept = new Set<string>()
    for (;;) {
      const flagged = await triageRound(base, guard, kept)
      const revised = await noteGate(REQUIREMENTS, () => answerProductQuestions(flagged))
      keepUnchanged(REQUIREMENTS, flagged, kept)
      if (!revised) return
    }
  })
