@inmem
Feature: fix lands a handed-off praise note with no change

  A note that asks for nothing still reaches `notes.fixing`, which may land
  without an edit; the review that follows catches an unaddressed note.

  Scenario: a praise-only note is fixed with no change, and both review files are removed
    Given the shipped workflows, as gtd-wf config prints them
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      """
    And the working tree is committed as "feat: add calculator"
    And a file ".gtd/REVIEW.orig.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function
      """
    And a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function — LGTM
      """
    And the working tree is committed as "chore: hand off a review"
    And step "notes.fixing" changes nothing
    And step "notes.closing" runs its script
    When gtd opens door "fix"
    And the process is driven leniently
    Then the process rests at "build.health.check"
    And the commit subjects end with:
      """
      gtd(human): notes.fixing
      gtd(agent): notes.fixing → notes.closing
      gtd(check): notes.closing → build.health.check
      """
    And ".gtd/REVIEW.md" does not exist
    And ".gtd/REVIEW.orig.md" does not exist
