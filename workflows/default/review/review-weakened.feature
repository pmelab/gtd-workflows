@inmem
Feature: the review flags an existing scenario that lost an assertion

  Scenario wording is not frozen while a workflow builds: the human signs the
  scenarios off once, in the review. A `Then` line (or an `And`/`But`
  continuing one) that a `.feature` file existing at the review's base no
  longer carries is listed in the reviewer's prompt, which asks for a
  `Weakened:` note on that scenario. A reworded `Given` or `When` is not.

  Background:
    Given the shipped workflows, as gtd install scaffolds them
    And an environment variable "GTD_QUALITYREVIEWS" set to ""
    And a file "spec/widget.feature" with:
      """
      Feature: Widget
        Scenario: shown
          Given a widget
          When it renders
          Then it is shown
          And it is blue
      """
    And the working tree is committed as "test: widget scenario"
    And step "review-gate.check" changes nothing

  Scenario: a reworded Then is listed as a weakened scenario
    Given the text "Then it is shown" in "spec/widget.feature" is replaced with "Then it is displayed"
    And the working tree is committed as "test: reword widget"
    When gtd opens door "review" with "HEAD~1"
    And the process is driven
    Then the process rests at "build.review.reviewing"
    And the resting step's content contains "spec/widget.feature — Scenario: shown — Then it is shown"
    And the resting step's content contains "Open the note of each scenario that lost one with `Weakened:`"
    And the resting step's content does not contain "And it is blue"

  Scenario: a reworded Given is not listed
    Given the text "Given a widget" in "spec/widget.feature" is replaced with "Given a fresh widget"
    And the working tree is committed as "test: reword widget"
    When gtd opens door "review" with "HEAD~1"
    And the process is driven
    Then the process rests at "build.review.reviewing"
    And the resting step's content contains "Write `.gtd/REVIEW.md` in this exact format"
    And the resting step's content does not contain "Weakened"
