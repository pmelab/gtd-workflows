@inmem
Feature: a question at the review gate gets an answer at the same gate, not a lap

  A `- H:` footnote thread in `.gtd/REVIEW.md`, or a `// H:` comment in a
  changed file, is answered by `build.review.collecting` in place, and the
  process rests at the review gate again: no triage, no requirements. A
  thread whose last entry is the agent's waits on the human, and refuses a
  sign-off until the human concludes or deletes it.

  Background:
    Given the shipped workflows, as gtd-wf config prints them
    And the environment variable "GTD_QUALITYREVIEWS" is ""
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      """
    And the working tree is committed as "feat: add calculator"
    And step "review-gate.check" changes nothing
    And step "build.review.reviewing" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function
      """
    When gtd opens door "review" with "HEAD~1"
    And the process is driven
    Then the process rests at "build.review.await-review"

  Scenario: a code thread question gets one A: reply and the gate rests again, no lap
    Given a file "src/calc.ts" with:
      """
      // H: why not multiply?
      export const add = (a: number, b: number) => a + b
      """
    And step "build.review.collecting" writes "src/calc.ts" with:
      """
      // H: why not multiply?
      // A: this is the addition helper.
      export const add = (a: number, b: number) => a + b
      """
    When gtd lands
    And the process is driven
    Then the process rests at "build.review.await-review"
    And the commit subjects end with:
      """
      gtd(human): build.review.await-review → build.review.collecting
      gtd(agent): build.review.collecting → build.review.await-review
      """
    And ".gtd/REQUIREMENTS.md" does not exist
    And landing is refused with "src/calc.ts:1"

  Scenario: a hand-edit from an earlier reply round is reverted by the re-unwind, back to its reviewed content
    Given step "build.review.closing" runs its script
    And a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function[^why]

      [^why]:
          - H: why not multiply?
      """
    And a file "src/calc.ts" with:
      """
      export const add = (a: number, b: number) => a + b
      // TODO: also export multiply
      """
    And step "build.review.collecting" writes ".gtd/REQUIREMENTS.md" with:
      """
      ## Multiply

      Export `multiply()`.
      """
    And step "build.review.collecting" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function[^why]

      [^why]:
          - H: why not multiply?
          - A: this is the addition helper.
      """
    And step "re-unwind" runs its script
    When gtd lands
    And the process is driven
    Then the process rests at "build.review.await-review"
    Given a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function
      """
    When gtd lands
    And the process is driven
    Then the process rests at "feedback.fixing"
    And the commit subjects end with:
      """
      gtd(agent): build.review.collecting → build.review.await-review
      gtd(human): build.review.await-review → build.review.closing
      gtd(check): build.review.closing → re-unwind
      gtd(check): re-unwind → feedback.fixing
      """
    And "src/calc.ts" does not contain "TODO"

  Scenario: the collecting turn's capture names the review commit, never inlines a diff
    Given step "build.review.closing" runs its script
    And judge step "build.review.triage" answers:
      """
      [{"id":"note-1","answer":"edit","p":0.95}]
      """
    And the text "new add function" in ".gtd/REVIEW.md" is replaced with "new add function — also handle negatives"
    When gtd lands
    And the process is driven
    Then the process rests at "build.review.collecting"
    And the resting step's content contains the hash of the commit "gtd(human): build.review.await-review → build.review.triage"
    And the resting step's content contains ".gtd/REVIEW.md"
    And the resting step's content does not contain "diff --git"

  Scenario: folds from an in-loop collect survive a judged-approving last round
    Given step "build.review.closing" runs its script
    And a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function[^a][^b]

      [^a]:
          - H: add subtract too.

      [^b]:
          - H: why not multiply?
      """
    And step "build.review.collecting" writes ".gtd/REQUIREMENTS.md" with:
      """
      ## Subtract

      Export `subtract()`.
      """
    And step "build.review.collecting" writes ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function[^b]

      [^b]:
          - H: why not multiply?
          - A: this is the addition helper.
      """
    When gtd lands
    And the process is driven
    Then the process rests at "build.review.await-review"
    Given a file ".gtd/REVIEW.md" with:
      """
      # Review: abc1234

      <!-- base: 0000000 -->

      ## calc

      - [ ] ./src/calc.ts#1-1
        new add function — looks good
      """
    And judge step "build.review.triage" answers:
      """
      [{"id":"note-1","answer":"praise","p":0.99}]
      """
    When gtd lands
    And the process is driven leniently
    Then the process rests at "re-unwind"
    And the commit subjects end with:
      """
      gtd(human): build.review.await-review → build.review.triage
      gtd(judge): build.review.triage → build.review.closing
      gtd(check): build.review.closing → re-unwind
      """
    And ".gtd/REQUIREMENTS.md" contains "subtract"

  Rule: a footnote thread is answered in the review

    Background:
      Given a file ".gtd/REVIEW.md" with:
        """
        # Review: abc1234

        <!-- base: 0000000 -->

        ## calc

        - [ ] ./src/calc.ts#1-1
          new add function[^why]

        [^why]:
            - H: why not multiply?
        """
      And step "build.review.collecting" writes ".gtd/REVIEW.md" with:
        """
        # Review: abc1234

        <!-- base: 0000000 -->

        ## calc

        - [ ] ./src/calc.ts#1-1
          new add function[^why]

        [^why]:
            - H: why not multiply?
            - A: this is the addition helper.
        """

    Scenario: a reply-only round rests at the review gate again, with no requirements written
      When gtd lands
      And the process is driven
      Then the process rests at "build.review.await-review"
      And the commit subjects end with:
        """
        gtd(human): build.review.await-review → build.review.collecting
        gtd(agent): build.review.collecting → build.review.await-review
        """
      And ".gtd/REQUIREMENTS.md" does not exist
      And ".gtd/REVIEW.md" contains "A: this is the addition helper."

    Scenario: a sign-off is refused while the thread waits on the human
      When gtd lands
      And the process is driven
      Then landing is refused with "open-threads"

    Scenario: a collecting turn that leaves the thread ending in H: is refused
      Given step "build.review.carrying" runs its script
      And step "build.review.closing" runs its script
      And step "build.review.collecting" from now on changes nothing
      When gtd lands
      Then driving the process is refused with "unanswered-threads"
