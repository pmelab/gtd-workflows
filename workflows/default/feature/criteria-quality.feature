@inmem
Feature: a judge rejects criteria that are not observable behaviour

  After every `design.triage` round `design.criteria` rates each acceptance
  criterion: `keep`, or a rejection (`internal`, `existing`, `upstream`,
  `exact`, `tier`, `negative`) at `criteriaQualityMinP` or above. Rejected
  criteria go back to triage with their reasons, at most twice; whatever the
  judge still rejects is listed at the design gate. A flagged criterion the
  human leaves word for word there is an ordinary criterion: it is never
  judged again in that design.

  Background:
    Given the shipped workflows, as gtd-wf config prints them
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And the environment variable "GTD_FLAG_RISK_TIER" is "0"
    And a file "src/greeting.ts" with:
      """
      export const greeting = "Helo, world"
      """
    And the working tree is committed as "feat: add greeting"
    And a file "TODO.md" with:
      """
      # Fix the typo

      greeting says "Helo"; make it "Hello".
      """
    And step "unwind" changes nothing
    And step "start-gate.check" changes nothing
    And step "design.triage" writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Impact

      - the greeting module

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: `greeting` reads "Hello, world".
      - AC-2: no other export changes.
      """

  Scenario: criteria the judge keeps reach the design gate unlisted
    Given judge step "design.criteria" answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"keep","p":0.9}]
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    And the resting step's content does not contain "still rejects"
    And the commit subjects end with:
      """
      gtd(check): start-gate.check → design.triage
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.gate.answer
      """

  Scenario: a rejected criterion goes back to triage with its reason
    Given judge step "design.criteria", when its questions contain "AC-2", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"negative","p":0.8}]
      """
    And judge step "design.criteria", when its questions contain "AC-1", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9}]
      """
    And step "design.triage", when prompted with "- AC-2 (negative: claims something stays absent, unchanged or unreachable): no other export changes.", writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Impact

      - the greeting module; no other export changes

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: `greeting` reads "Hello, world".
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    And the resting step's content does not contain "still rejects"
    And the commit subjects end with:
      """
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.triage
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.gate.answer
      """

  Scenario: a retry that changes nothing hands the rejection to the human
    Given judge step "design.criteria" answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"negative","p":0.8}]
      """
    And step "design.triage", when prompted with "Rejected criteria", writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Impact

      - the greeting module

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: `greeting` reads "Hello, world".
      - AC-2: no other export changes.
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    And the resting step's content contains "The criteria judge still rejects these acceptance criteria"
    And the resting step's content contains "- AC-2 (negative: claims something stays absent, unchanged or unreachable): no other export changes."
    And the commit subjects end with:
      """
      gtd(judge): design.criteria → design.triage
      gtd(agent): design.triage → design.gate.answer
      """

  Scenario: after two retries the judge's rejections go to the human
    Given judge step "design.criteria" answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"negative","p":0.8}]
      """
    And a file ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Impact

      - the greeting module

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: `greeting` reads "Hello, world".
      - AC-2: no other export changes.
      """
    And step "design.triage" is no longer scripted
    And step "design.triage" appends to ".gtd/REQUIREMENTS.md":
      """

      Revised.
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    And the resting step's content contains "The criteria judge still rejects these acceptance criteria"
    And the commit subjects end with:
      """
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.triage
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.triage
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.gate.answer
      """

  Scenario: a rejection below criteriaQualityMinP keeps the criterion
    Given judge step "design.criteria" answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"negative","p":0.4}]
      """
    When the process is driven
    Then the process rests at "design.gate.answer"
    And the resting step's content does not contain "still rejects"

  Scenario: a flagged criterion the human keeps word for word is never judged again
    Given judge step "design.criteria", when its questions contain "criterion AC-2,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9},{"id":"AC-2","answer":"negative","p":0.8}]
      """
    And judge step "design.criteria", when its questions contain "criterion AC-1,", answers:
      """
      [{"id":"AC-1","answer":"keep","p":0.9}]
      """
    And step "design.gate.answer", when prompted with "still rejects", writes ".gtd/REQUIREMENTS.md" with:
      """
      # Requirements

      ## Impact

      - the greeting module, and nothing else

      ## Release Flag

      new

      ## Acceptance Criteria

      - AC-1: `greeting` reads "Hello, world".
      - AC-2: no other export changes.
      """
    And step "design.gate.answer" changes nothing
    When the process is driven
    Then the process rests at "seam.naive"
    And the commit "gtd(human): design.gate.answer → design.triage" has a body containing "Gtd-Mark: criterion-kept=AC-2 negative"
    And the commit subjects end with:
      """
      gtd(human): design.gate.answer → design.triage
      gtd(agent): design.triage → design.criteria
      gtd(judge): design.criteria → design.gate.answer
      gtd(human): design.gate.answer → seam.naive
      """
