@inmem
Feature: a red suite the fix loop cannot repair escalates to a person, twice at most

  An identical red round (or the fix cap) escalates: `health.describe` writes
  a fix-design document to `.gtd/ESCALATION.md`, and the person at
  `health.stop` may edit it or land it untouched; the next fix turn is told
  to follow it. The second escalation since the last green run rests at the
  terminal `health.exhausted` instead, with the document still on disk, and
  landing it untouched buys another attempt.

  Background:
    Given a gtd config with:
      """
      import { fixCheck, healthy } from "#workflow"
      import { agent, scope, workflow } from "@pmelab/gtd/flows"

      const defaults = { judgeIdenticalMinP: "0.7" }
      export const held = workflow(async () => {
        await scope("start", () => agent("first", "go"))
        await healthy(() => fixCheck())
      }, { defaults })
      export default held
      """
    And step "start.first" writes "src/a.ts" with:
      """
      export const a = 1
      """
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      the same failure, restated
      """
    And step "fix" deletes ".gtd/FEEDBACK.md"
    And judge step "health.judge" answers:
      """
      [{"id":"verdict","answer":"identical","p":0.95}]
      """
    And step "health.recheck" writes ".gtd/FEEDBACK.md" with:
      """
      the same failure, on re-run
      """

  Scenario: the describe turn writes the document, the stop gate hands it on untouched, and the second round is exhausted
    When gtd starts workflow "held"
    And the process is driven
    Then the process rests at "health.describe"
    And the resting step's content contains ".gtd/FEEDBACK.md"
    And the resting step's content contains "git log -p -- .gtd/FEEDBACK.md"
    And the resting step's content contains ".gtd/ESCALATION.md"
    Given step "health.describe" writes ".gtd/ESCALATION.md" with:
      """
      What's failing: the suite still reports the same failure.
      """
    When the process is driven
    Then the process rests at "health.stop"
    And the resting step's content contains ".gtd/ESCALATION.md"
    And the resting step's content contains "Edit it"
    # A genuinely clean landing hands the document on to the next fix turn.
    Given step "health.stop" changes nothing
    And step "fix" is prompted with ".gtd/ESCALATION.md"
    When the process is driven
    Then the process rests at "health.exhausted"
    And the commit subjects end with:
      """
      gtd(check): health.check → health.judge
      gtd(judge): health.judge → health.recheck
      gtd(check): health.recheck → health.exhausted
      """
    And ".gtd/ESCALATION.md" contains "What's failing"
    And the resting step's content contains "exhausted"
    And the resting step's content contains ".gtd/ESCALATION.md"
    And the resting step's content contains ".gtd/FEEDBACK.md"
    # Landing the terminal stop untouched buys another attempt.
    Given step "health.exhausted" changes nothing
    And step "fix" is no longer scripted
    When the process is driven
    Then the process rests at "fix"
    And the last commit subject is "gtd(human): health.exhausted → fix"
