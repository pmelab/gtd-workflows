@inmem
Feature: planning and coding turns take their models from env.plannerModel and env.coderModel

  `envDefaults` sets `plannerModel` to `smart` and `coderModel` to `base`;
  `GTD_PLANNERMODEL` / `GTD_CODERMODEL` repoint every turn of that tier at
  once.

  Background:
    Given the shipped workflows, as gtd-wf config prints them
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing

  Scenario: a planner-tier state runs on env.plannerModel
    Given a file "NOTE.md" with:
      """
      a sketch
      """
    When the process is driven
    Then the process rests at "design.triage"
    And the output of gtd "next --json" contains "\"model\":\"smart\""

  Scenario: a coder-tier state runs on env.coderModel
    Given a file "NOTE.md" with:
      """
      a sketch
      """
    And step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      a sketch

      ## Impact

      - the greeting module

      ## Acceptance Criteria

      - AC-1: the change behaves as described.
      """
    And step "design.gate.answer" changes nothing
    When the process is driven
    Then the process rests at "seam.naive"
    And the output of gtd "next --json" contains "\"model\":\"base\""

  Scenario: a GTD_PLANNERMODEL override repoints a planner-tier state
    Given the environment variable "GTD_PLANNERMODEL" is "opus"
    And a file "NOTE.md" with:
      """
      a sketch
      """
    When the process is driven
    Then the process rests at "design.triage"
    And the output of gtd "next --json" contains "\"model\":\"opus\""
    And the output of gtd "next --json" does not contain "\"model\":\"smart\""
