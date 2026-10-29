@inmem
Feature: each phase of the shipped workflow is its own conversation

  A step's memory key is its scope plus the commit its run started from:
  design, seam and build each start their own conversation, and the review
  inside build its own again.

  Scenario: design and seam are separate conversations
    Given the shipped workflows, as gtd install scaffolds them
    And a file "NOTE.md" with:
      """
      a sketch
      """
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing
    When the process is driven
    Then the process rests at "design.triage"
    And the output of gtd "next --json=memory" contains "design#"
    Given step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      Build a thing.

      ## Impact

      - the greeting module

      ## Acceptance Criteria

      - AC-1: the change behaves as described.
      """
    And step "design.gate.answer" changes nothing
    When the process is driven
    Then the process rests at "seam.naive"
    And the output of gtd "next --json=memory" contains "seam#"

  Scenario: the build tail and its review are separate conversations
    Given the shipped workflows, as gtd install scaffolds them
    And an environment variable "GTD_QUALITYREVIEWS" set to ""
    And step "fix-precheck" writes ".gtd/FEEDBACK.md" with:
      """
      a failing test
      """
    When gtd starts workflow "fix"
    And the process is driven
    Then the process rests at "build.fix"
    And the output of gtd "next --json=memory" contains "build#"
    Given step "build.fix" deletes ".gtd/FEEDBACK.md"
    And step "build.fix" writes "src/thing.ts" with:
      """
      export const thing = 1
      """
    And step "build.health.check" changes nothing
    When the process is driven
    Then the process rests at "build.review.reviewing"
    And the output of gtd "next --json=memory" contains "build.review#"
