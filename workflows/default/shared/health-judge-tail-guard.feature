@inmem
Feature: health.judge never manufactures "identical" from two unusably-cut tails

  The judge budget's line-boundary cut can render `""` for a report whose
  last bytes hold no full line, or leave two different reports looking alike
  once their differing starts are cut away. Reading either as proof the round
  is unchanged would end the retry loop on evidence nobody saw. So an
  "identical" answer only escalates when the budget cut neither report;
  otherwise the round goes on to the next fix.

  Background:
    Given a gtd config with:
      """
      import { healthy } from "#workflow"
      import { agent, human } from "@pmelab/gtd/flows"

      export const defaults = { judgeIdenticalMinP: "0.7", judgeBudgetBytes: "32768" }
      export const held = async () => {
        await agent("first", "go")
        await healthy(() => agent("fix", "go"))
        await human("done")
      }
      export default held
      """
    And step "first" writes "src/attempt.ts" with:
      """
      export const attempt = 0
      """

  Scenario: a judgeBudgetBytes too small for either tail to keep a full line forbids identical
    Given an environment variable "GTD_JUDGEBUDGETBYTES" set to "4"
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      attempt 1 failed
      <!-- gtd check abc1234 -->
      """
    When gtd starts workflow "held"
    And the process is driven
    Then the process rests at "fix"
    Given step "health.check" is no longer scripted
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      attempt 2 failed
      <!-- gtd check def5678 -->
      """
    And step "fix" deletes ".gtd/FEEDBACK.md"
    And step "fix" writes "src/attempt.ts" with:
      """
      export const attempt = 2
      """
    When the process is driven
    Then the process rests at "health.judge"
    # At `judgeBudgetBytes: 4`, each report keeps at most its last 2 bytes —
    # no full line — so both render "".
    Given judge step "health.judge" answers:
      """
      [{"id":"verdict","answer":"identical","p":0.99}]
      """
    And step "fix" is no longer scripted
    When the process is driven
    Then the process rests at "fix"
    And the last commit subject is "gtd(judge): health.judge → fix"

  Scenario: two equal-length reports that differ before the cut but match after it forbid identical
    # 40 bytes across two reports keeps only each one's "shared tail line".
    Given an environment variable "GTD_JUDGEBUDGETBYTES" set to "40"
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      attempt one failed here
      shared tail line
      <!-- gtd check abc1234 -->
      """
    When gtd starts workflow "held"
    And the process is driven
    Then the process rests at "fix"
    Given step "health.check" is no longer scripted
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      attempt two failed here
      shared tail line
      <!-- gtd check def5678 -->
      """
    And step "fix" deletes ".gtd/FEEDBACK.md"
    And step "fix" writes "src/attempt.ts" with:
      """
      export const attempt = 2
      """
    When the process is driven
    Then the process rests at "health.judge"
    Given judge step "health.judge" answers:
      """
      [{"id":"verdict","answer":"identical","p":0.99}]
      """
    And step "fix" is no longer scripted
    When the process is driven
    Then the process rests at "fix"
    And the last commit subject is "gtd(judge): health.judge → fix"

  Scenario: two genuinely identical reports still reach the identical verdict and escalate
    Given step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      the same failure, restated
      <!-- gtd check abc1234 -->
      """
    When gtd starts workflow "held"
    And the process is driven
    Then the process rests at "fix"
    Given step "health.check" is no longer scripted
    And step "health.check" writes ".gtd/FEEDBACK.md" with:
      """
      the same failure, restated
      <!-- gtd check def5678 -->
      """
    And step "fix" deletes ".gtd/FEEDBACK.md"
    And step "fix" writes "src/attempt.ts" with:
      """
      export const attempt = 2
      """
    And judge step "health.judge" answers:
      """
      [{"id":"verdict","answer":"identical","p":0.99}]
      """
    And step "health.recheck" writes ".gtd/FEEDBACK.md" with:
      """
      the same failure, restated
      <!-- gtd check 0123abc -->
      """
    When the process is driven
    Then the process rests at "health.describe"
    And the commit subjects end with:
      """
      gtd(check): health.check → health.judge
      gtd(judge): health.judge → health.recheck
      gtd(check): health.recheck → health.describe
      """
