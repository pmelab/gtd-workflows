@inmem
Feature: the review gate's contract, and a feedback round's review base

  The reviewer writes `.gtd/REVIEW.md` in a fixed format; the gate tells the
  person how to sign off (leave no comment — a tick only records a hunk was
  read) or give feedback, and that deleting the file is refused. A feedback
  round's re-review starts from that round's own boundary, not the process
  start.

  Background:
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
    And judge step "design.criteria", when its questions contain "criterion AC-2,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"keep","p":0.9}]
      """
    And judge step "design.criteria", when its questions contain "criterion AC-1,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9}]
      """
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And the ref "refs/tags/base" points at HEAD
    And a file "src/thing.ts" with:
      """
      export const thing = 1
      """
    And the working tree is committed as "feat: add thing"
    And step "review-gate.check" changes nothing
    And step "build.health.check" changes nothing

  Scenario: a sign-off lands with a box still unticked, after the gate states its contract
    When gtd starts workflow "review" with "--var reviewBase=base"
    And the process is driven
    Then the process rests at "build.review.reviewing"
    And the resting step's content contains "Write `.gtd/REVIEW.md` in this exact format"
    Given step "build.review.reviewing" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## Chunk

      - [ ] ./src/thing.ts#1-1
        the thing
      - [ ] ./src/thing.ts#1-1
        the thing again
      """
    When the process is driven
    Then the process rests at "build.review.await-review"
    And the resting step's content contains "**Sign off** — leave no comment"
    And the resting step's content contains "**Leave notes** — a note on a"
    And the resting step's content contains "Deleting `.gtd/REVIEW.md` is refused."
    Given a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## Chunk

      - [x] ./src/thing.ts#1-1
        the thing
      - [ ] ./src/thing.ts#1-1
        the thing again
      """
    When gtd lands
    Then the last commit subject is "gtd(human): build.review.await-review → build.review.closing"
    Given step "build.review.closing" runs its script
    When the process is driven
    Then the process rests at "idle"

  Scenario: a feedback round's re-review is based at that round's own boundary
    Given step "build.review.reviewing" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## Chunk

      - [ ] ./src/thing.ts#1-1
        the thing
      """
    When gtd starts workflow "review" with "--var reviewBase=base"
    And the process is driven
    Then the process rests at "build.review.await-review"
    Given a file "src/thing.ts" with:
      """
      export const thing = 1
      // TODO: also export doubled
      """
    When gtd lands
    Then the last commit subject is "gtd(human): build.review.await-review → build.review.closing"
    Given step "build.review.reviewing" is no longer scripted
    And step "build.review.closing" runs its script
    And step "build.review.collecting" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      - export doubled

      ## Impact

      - the thing module

      ## Acceptance Criteria

      - AC-1: doubled is exported.
      """
    And step "re-unwind" runs its script
    And step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      - export doubled, designed

      ## Impact

      - the thing module

      ## Acceptance Criteria

      - AC-1: doubled is exported.
      """
    And step "design.gate.answer" changes nothing
    And step "implement.building" writes "src/doubled.ts" with:
      """
      export const doubled = 2
      """
    And step "implement.health.check" changes nothing
    And step "implement.closing" runs its script
    When the process is driven
    Then the process rests at "build.review.reviewing"
    And the resting step's content contains the hash of the commit "gtd(human): build.review.await-review → build.review.closing"
