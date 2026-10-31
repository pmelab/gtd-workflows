import { human } from "@pmelab/gtd/flows"
import type { CollectRound } from "@pmelab/gtd/workflow-kit"
import * as t from "../shared/text.js"
import { riskTierOn } from "./tier.js"
import { planner, REFACTOR, REQUIREMENTS } from "../shared/steps.js"

// Kept on the published feature entry.
export { answerReviewQuestions, collecting, fixNits } from "../shared/steps.js"

/** Turn the sketch since `base` into `.gtd/REQUIREMENTS.md`; with `rejected`, revise those criteria. */
export const triage = (
  base: string,
  rejected: readonly t.RejectedCriterion[] = [],
): Promise<void> =>
  t.agentWithSkills("triage", t.designTriagePrompt(base, riskTierOn(), rejected), {
    label: rejected.length === 0 ? "Triaging the change" : "Revising the rejected criteria",
    file: REQUIREMENTS,
    mode: "qa",
    model: planner(),
    system: t.designSystem(),
    // Keeping a criterion the judge got wrong is a legitimate answer.
    allowEmpty: rejected.length > 0,
  })

export const answerProductQuestions = (
  flagged: readonly t.RejectedCriterion[] = [],
): Promise<void> =>
  human("gate.answer", {
    message: t.designGateAnswerMessage(riskTierOn(), flagged),
    label: "Awaiting your product answers",
    file: REQUIREMENTS,
    mode: "qa",
    acceptClean: true,
  })

/** Turn the refactor review round `capture` describes into `.gtd/REFACTOR.md`, or change nothing. */
export const refactorCollecting = (
  capture: string,
  round: CollectRound,
  strays: readonly string[],
): Promise<void> =>
  t.agentWithSkills(
    "review.collecting",
    t.buildReviewCollectingPrompt(capture, { strays, round }),
    {
      label: "Collecting your refactor feedback",
      file: REFACTOR,
      model: planner(),
      system: t.reviewerSystem(),
      allowEmpty: true,
    },
  )
