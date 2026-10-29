@inmem
Feature: the green-baseline start gate runs the suite before a process builds

  `idle` leads into `unwind`, which reverts the opening commit's diff out of
  the working tree before `start-gate.check` runs, so the gate's suite run
  sees the baseline. A red run is re-run once as `start-gate.recheck`; green
  there proceeds, recorded as `Gtd-Mark: flaky=start-gate.check`. Red again
  halts at the human `start-gate.blocked` gate, which loops back to the check
  once the human repairs the failures.

  Background:
    Given the shipped workflows, as gtd-wf config prints them
    And step "unwind" runs its script

  Scenario: a red baseline halts at start-gate.blocked, then a fix re-runs the gate to green
    Given a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failing: baseline broken
      """
    And step "start-gate.recheck" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failing: baseline still broken
      """
    When the process is driven
    Then the process rests at "start-gate.blocked"
    And the resting step's content contains "test baseline is red"
    And the resting step's content contains "gtd start fix"
    And no commit body contains "Gtd-Mark: flaky="
    Given step "start-gate.check" from now on changes nothing
    And step "start-gate.blocked" deletes ".gtd/FEEDBACK.md"
    And step "start-gate.blocked" writes "src/baseline-fix.ts" with:
      """
      export const fixed = true
      """
    When the process is driven
    Then the process rests at "design.triage"
    And the commit subjects end with:
      """
      gtd(check): start-gate.check → start-gate.recheck
      gtd(check): start-gate.recheck → start-gate.blocked
      gtd(human): start-gate.blocked → start-gate.check
      gtd(check): start-gate.check → design.triage
      """

  Scenario: a leftover file the green check sweeps does not misroute the gate
    Given a file ".gtd/REVIEW_RAW.md" with:
      """
      stale raw review capture left by an abandoned process
      """
    And the working tree is committed as "chore: leave a capture behind"
    And a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" deletes ".gtd/REVIEW_RAW.md"
    When the process is driven
    Then the process rests at "design.triage"
    And the last commit subject is "gtd(check): start-gate.check → design.triage"

  Scenario: a red run that also swept a leftover file still halts at start-gate.blocked
    Given a file ".gtd/REVIEW_RAW.md" with:
      """
      stale raw review capture left by an abandoned process
      """
    And the working tree is committed as "chore: leave a capture behind"
    And a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" deletes ".gtd/REVIEW_RAW.md"
    And step "start-gate.check" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failing: baseline broken
      """
    And step "start-gate.recheck" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failing: baseline still broken
      """
    When the process is driven
    Then the process rests at "start-gate.blocked"
    And the commit subjects end with:
      """
      gtd(check): start-gate.check → start-gate.recheck
      gtd(check): start-gate.recheck → start-gate.blocked
      """

  Scenario: a green baseline proceeds from the gate into design.triage
    Given the environment variable "GTD_TESTCOMMAND" is "true"
    And the command "true" exits 0
    And a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" runs its script
    When the process is driven
    Then the process rests at "design.triage"
    And "NOTE.md" does not exist
    And ".gtd/FEEDBACK.md" does not exist

  Scenario: the unwind reverts a note and a hand-edited code change alike, while both survive in the entry commit
    Given the environment variable "GTD_TESTCOMMAND" is "true"
    And the command "true" exits 0
    And a file "src/real.ts" with:
      """
      export const real = 1
      """
    And a file "SCRATCH.md" with:
      """
      idea: also expose a helper that doubles real
      """
    And step "start-gate.check" runs its script
    When the process is driven
    Then the process rests at "design.triage"
    And "src/real.ts" does not exist
    And "SCRATCH.md" does not exist
    And the commit subjects end with:
      """
      gtd(human): idle → unwind
      gtd(check): unwind → start-gate.check
      gtd(check): start-gate.check → design.triage
      """

  Scenario: a red baseline halts at start-gate.blocked with the failing output recorded
    Given the environment variable "GTD_TESTCOMMAND" is "false"
    And the command "false" exits 1
    And a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" runs its script
    And step "start-gate.recheck" runs its script
    When the process is driven
    Then the process rests at "start-gate.blocked"
    And "NOTE.md" does not exist
    And ".gtd/FEEDBACK.md" contains "the test command failed"

  Scenario: a red baseline that passes on its re-check proceeds to design.triage, recorded as flaky
    Given a file "NOTE.md" with:
      """
      Build a thing.
      """
    And step "start-gate.check" writes ".gtd/FEEDBACK.md" with:
      """
      1 test failing: timed out
      """
    And step "start-gate.recheck" deletes ".gtd/FEEDBACK.md"
    When the process is driven
    Then the process rests at "design.triage"
    And the last commit subject is "gtd(check): start-gate.recheck → design.triage"
    And the last commit body contains "Gtd-Mark: flaky=start-gate.check"

  Scenario: a sketch written only under .gtd/ starts a process
    Given a file ".gtd/TODO.md" with:
      """
      - [ ] sketch: add a greeter
      """
    And step "start-gate.check" changes nothing
    When the process is driven
    Then the process rests at "design.triage"
    And the commit subjects end with:
      """
      gtd(human): idle → unwind
      gtd(check): unwind → start-gate.check
      gtd(check): start-gate.check → design.triage
      """
