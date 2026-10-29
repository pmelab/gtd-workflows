@inmem
Feature: the health check runs "testCommand"

  `build.health.check` runs the `testCommand` var and, when it fails, leaves
  its output in `.gtd/FEEDBACK.md`, stamped with the commit it ran at. The var
  defaults to `npm test`; the `testCommand` factory option and
  `GTD_TESTCOMMAND` override it.

  Background:
    Given the shipped workflows, as gtd install scaffolds them
    And the environment variable "GTD_QUALITYREVIEWS" is "correctness"
    And step "fix-precheck" writes ".gtd/FEEDBACK.md" with:
      """
      1 failing test
      """
    And step "build.fix" deletes ".gtd/FEEDBACK.md"
    And step "build.fix" writes "src/thing.ts" with:
      """
      export const thing = 1
      """
    And step "build.health.check" runs its script

  Scenario: the default testCommand runs the project's npm test script
    Given the command "npm test" exits 1 with:
      """
      default-wins
      """
    When gtd starts workflow "fix"
    And the process is driven
    Then the process rests at "build.health.judge"
    And the commit subjects end with:
      """
      gtd(agent): build.fix → build.health.check
      gtd(check): build.health.check → build.health.judge
      """
    And ".gtd/FEEDBACK.md" contains "default-wins"
    And ".gtd/FEEDBACK.md" contains "<!-- gtd check "

  Scenario: a GTD_TESTCOMMAND environment variable overrides the default
    Given the environment variable "GTD_TESTCOMMAND" is "run-env-tests"
    And the command "run-env-tests" exits 1 with:
      """
      env-wins
      """
    When gtd starts workflow "fix"
    And the process is driven
    Then ".gtd/FEEDBACK.md" contains "env-wins"

  Scenario: a green run leaves no FEEDBACK.md and lands on the quality lap
    Given the command "npm test" exits 0
    When gtd starts workflow "fix"
    And the process is driven
    Then ".gtd/FEEDBACK.md" does not exist
    And the last commit subject is "gtd(check): build.health.check → build.quality.correctness.reviewing"
