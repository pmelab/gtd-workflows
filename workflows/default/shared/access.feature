@inmem
Feature: the shipped workflow's scope access holds at landing

  A quality lens may write only its steering file: a lens turn that changes
  `src/` is refused when it lands. A review's collecting turn answering a code
  thread may write the threaded file.

  Scenario: a review lens that writes src/ is refused at landing
    Given the shipped workflows, as gtd-wf config prints them
    And the environment variable "GTD_QUALITYREVIEWS" is "owasp-security"
    And step "fix-precheck" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failed
      """
    And step "build.fix" deletes ".gtd/FEEDBACK.md"
    And step "build.fix" writes "src/thing.ts" with:
      """
      export const thing = 1
      """
    And step "build.health.check" changes nothing
    When gtd starts workflow "fix"
    And the process is driven
    Then the process rests at "build.quality.owasp-security.reviewing"
    And the output of gtd "next --json=access.write" contains ".gtd/QUALITY.md"
    And the output of gtd "next --json=access.write" does not contain "src/"
    And the resting step's content contains "- This turn may write only: .gtd/QUALITY.md — anything else is refused when the turn lands"
    Given a file "src/thing.ts" with:
      """
      export const thing = 2
      """
    Then landing is refused with "  - src/thing.ts"
    And landing is refused with "allowed: .gtd/QUALITY.md"
    Given a file "src/thing.ts" with:
      """
      export const thing = 1
      """
    When gtd lands
    Then the last commit subject is "gtd(agent): build.quality.owasp-security.reviewing → build.review.reviewing"

  Scenario: a review turn answering a code thread in src/ lands with the file on the wire
    Given a gtd config with:
      """
      import { start, workflow } from "@pmelab/gtd/flows"
      import { afterTail, buildTail, gate, workflowOptions } from "#workflow"

      export { feature as default } from "#workflow"

      export const review = workflow(
        async () => {
          await gate("review-gate", "The baseline is red.")
          return afterTail(await buildTail(start()))
        },
        { ...workflowOptions, base: (_workflow, vars) => vars.reviewBase ?? "" },
      )
      """
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And the ref "refs/tags/base" points at HEAD
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      """
    And the working tree is committed as "feat: add calculator"
    And step "review-gate.check" changes nothing
    And step "build.health.check" changes nothing
    And step "build.review.reviewing" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function
      """
    When gtd starts workflow "review" with "--var reviewBase=base"
    And the process is driven
    Then the process rests at "build.review.await-review"
    Given a file "src/calc.ts" with:
      """
      // H: why not multiply?
      export const add = (a: number, b: number) => a + b
      """
    When gtd lands
    Then the last commit subject is "gtd(human): build.review.await-review → build.review.collecting"
    And the output of gtd "next --json=access.write" contains "src/calc.ts"
    And the output of gtd "next --json=access.write" contains ".gtd/REQUIREMENTS.md"
    Given a file "src/calc.ts" with:
      """
      // H: why not multiply?
      // A: this is the addition helper.
      export const add = (a: number, b: number) => a + b
      """
    When gtd lands
    Then the last commit subject is "gtd(agent): build.review.collecting → build.review.await-review"
