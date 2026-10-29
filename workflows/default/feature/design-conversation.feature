@inmem
Feature: the design gate always stops, threads get replies, open threads block moving on

  The requirements gate stops on every process, even with no open question.
  A footnote written as a `- H:` thread gets an `- A:` reply from
  `design.triage` and the process rests at the same gate again. A thread
  whose last entry is the agent's waits on the human: every landing at the
  gate is refused until the human replies with a conclusion or deletes it.

  Background:
    Given the shipped workflows, as gtd install scaffolds them
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      """
    And the working tree is committed as "feat: add calculator"
    And a file "TODO.md" with:
      """
      # Add a greeting

      greet() returns a greeting.
      """
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing

  Scenario: a design.triage turn that leaves a thread ending in H: is refused
    Given step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Concerns

      ### Greeting export

      - Add a `greet()` export.[^why]

      [^why]:
          - H: why a function?

      ## Impact

      - the greeting module

      ## Acceptance Criteria

      - AC-1: greet() returns a greeting.
      """
    Then driving the process is refused with "unanswered-threads"

  Scenario: the gate stops with no open question, and a clean re-run accepts the plan
    Given step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Concerns

      ### Greeting export

      - Add a `greet()` export.

      ## Impact

      - the greeting module

      ## Acceptance Criteria

      - AC-1: greet() returns a greeting.
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    When gtd lands
    Then the last commit subject is "gtd(human): design.gate.answer → seam.naive"

  Rule: a plan with an open question

    Background:
      Given step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
        """
        # Requirements

        ## Open Questions

        ### Which style?

        - [ ] plain
        - [ ] fancy

        ## Concerns

        ### Greeting export

        - Add a `greet()` export.

        ## Impact

        - the greeting module

        ## Acceptance Criteria

        - AC-1: greet() returns a greeting.
        """
      When the process is driven
      Then the process rests at "design.gate.answer"
      Given step "design.triage" from now on changes nothing

    Scenario: a round with no thread for the agent still needs every open question ticked
      Given the text "Add a `greet()` export." in ".gtd/REQUIREMENTS.md" is replaced with "Add a `greet()` export. Keep it tiny."
      Then landing is refused with "answer-completeness"

    Scenario: a footnote question is answered by design.triage, and an open thread then refuses landing
      Given a file ".gtd/REQUIREMENTS.md" with:
        """
        # Requirements

        ## Open Questions

        ### Which style?

        - [ ] plain
        - [ ] fancy

        ## Concerns

        ### Greeting export

        - Add a `greet()` export.[^why]

        [^why]:
            - H: why a function?

        ## Impact

        - the greeting module

        ## Acceptance Criteria

        - AC-1: greet() returns a greeting.
        """
      And step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
        """
        # Requirements

        ## Open Questions

        ### Which style?

        - [ ] plain
        - [ ] fancy

        ## Concerns

        ### Greeting export

        - Add a `greet()` export.[^why]

        [^why]:
            - H: why a function?
            - A: a constant cannot take a name later.

        ## Impact

        - the greeting module

        ## Acceptance Criteria

        - AC-1: greet() returns a greeting.
        """
      When gtd lands
      And the process is driven
      Then the process rests at "design.gate.answer"
      And the commit subjects end with:
        """
        gtd(human): design.gate.answer → design.triage
        gtd(agent): design.triage → design.gate.answer
        """
      And landing is refused with "open-threads"

    Scenario: a code H: question alone needs no tick, and design.triage must answer it
      Given a file "src/calc.ts" with:
        """
        // H: why not multiply?
        export const add = (a: number, b: number) => a + b
        """
      And step "design.triage" replaces the text "Add a `greet()` export." in ".gtd/REQUIREMENTS.md" with "Add a `greet()` export. Revised."
      When gtd lands
      Then the last commit subject is "gtd(human): design.gate.answer → design.triage"
      And driving the process is refused with "src/calc.ts:1"

    Scenario: design.triage deleting the requirements on a lap without addressing them is refused
      Given the text "- [ ] plain" in ".gtd/REQUIREMENTS.md" is replaced with "- [x] plain"
      And step "design.triage" deletes ".gtd/REQUIREMENTS.md"
      When gtd lands
      Then driving the process is refused with "without addressing its instructions"
