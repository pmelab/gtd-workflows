@inmem
Feature: the refactor review's lenses take their model hints from refactorQualityReviews alone

  Background:
    Given the shipped workflows, as gtd-wf config prints them
    And judge step "design.criteria", when its questions contain "criterion AC-2,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"keep","p":0.9}]
      """
    And judge step "design.criteria", when its questions contain "criterion AC-1,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9}]
      """
    And the environment variable "GTD_QUALITYREVIEWS" is "correctness=base"
    And the environment variable "GTD_REFACTORQUALITYREVIEWS" is "correctness, conventions=opus"
    And the environment variable "GTD_FLAG_RISK_TIER" is "0"
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      """
    And the working tree is committed as "feat: add calculator"
    And a file "TODO.md" with:
      """
      # Add subtract

      subtract(a, b) returns the difference.
      """
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing
    And step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Concerns

      ### Subtract

      - `subtract(a, b)` returns `a - b`.

      ## Impact

      - the greeting module

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: the change behaves as described.
      """
    And step "design.gate.answer" changes nothing

  Scenario: a refactor lens runs on its refactorQualityReviews hint, else its default
    Given step "seam.check" changes nothing
    And step "seam.naive" writes "src/acceptance.test.ts" with:
      """
      it("[AC-1] holds", () => {})
      """
    And step "seam.naive" writes "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      export const subtract = (a: number, b: number) => a - b
      """
    And judge step "seam.judge" answers:
      """
      [{"id":"shape","answer":"refactor-first","p":0.9}]
      """
    And step "seam.note" writes ".gtd/REFACTOR-NOTE.md" with:
      """
      Seam: the existing code the strays touch.
      """
    And step "refactor.deriving" runs its script
    And step "refactor.building" writes "src/calc.ts" with:
      """
      export const op = (a: number, b: number, sign: number) => a + sign * b
      export const add = (a: number, b: number) => op(a, b, 1)
      """
    And step "refactor.health.check" changes nothing
    And step "refactor.closing" runs its script
    When the process is driven
    Then the process rests at "refactor.build.quality.correctness.reviewing"
    And the output of gtd "next --json" contains "\"model\":\"smart\""
    Given step "refactor.build.quality.correctness.reviewing" changes nothing
    When the process is driven
    Then the process rests at "refactor.build.quality.conventions.reviewing"
    And the output of gtd "next --json" contains "\"model\":\"opus\""
