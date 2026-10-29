@inmem
Feature: design.triage raises every question above the bar in one lap

  The triage prompt holds the planner to a bar for raising a question and to
  raising all of them at once: a question held back for a later lap is a bug.

  Scenario: the triage prompt states the one-lap rule
    Given the shipped workflows, as gtd-wf config prints them
    And a file "NOTE.md" with:
      """
      a sketch
      """
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing
    When the process is driven
    Then the process rests at "design.triage"
    And the resting step's content contains "held back for a later lap is a bug"
    And the resting step's content contains "spec-driven-development, planning-and-task-breakdown"
