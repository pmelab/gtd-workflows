@inmem
Feature: a gtd.config.ts builds on the shipped workflows by importing them

  The workflow module's default export (`feature`) is the ordinary start, and
  its phases, steps, `defaults`, `summary`, `base`, `steering` and `skills`
  are named exports. A workflow of its own can re-export what it keeps and
  compose the rest, and the steps it reuses keep their full names — `skills`
  included, since dropping it from the re-export list silently empties every
  reused step's skill list instead of keeping the shipped defaults.

  Background:
    Given a gtd config with:
      """
      import { start } from "@pmelab/gtd/flows"
      import { afterTail, buildTail } from "#workflow"

      export { feature as default, defaults, envDefaults, summary, base, steering, skills } from "#workflow"

      export const hotfix = async () => afterTail(await buildTail(start(), { fixFirst: true }))
      """

  Scenario: an ordinary start runs the shipped flow, resting at its idle step
    Then the output of gtd "next" contains "No active gtd process"

  Scenario: a new named workflow reuses the shipped build tail, whose steps keep their full names
    When gtd starts workflow "hotfix"
    Then the last commit subject is "gtd(human): build.fix"
    Given a file "src/fix.ts" with:
      """
      export const fixed = true
      """
    When gtd lands
    Then the last commit subject is "gtd(agent): build.fix → build.health.check"

  Scenario: the shipped defaults are the reusing workflow's own
    When gtd starts workflow "hotfix" with "--var judgeBudgetBytes=65536"
    Then the last commit subject is "gtd(human): build.fix"
    And the last commit body contains "Gtd-Var: judgeBudgetBytes=65536"

  Scenario: the re-exported skills export keeps scope build's shipped skill list
    When gtd starts workflow "hotfix"
    Then the output of gtd "next --json=skills" contains "\"debugging-and-error-recovery\""

  Scenario: a config skills entry addresses scope build through the re-exported skills
    Given the gtd config ends with:
      """
      export const config = { skills: { build: ["my-org-runbook"] } }
      """
    When gtd starts workflow "hotfix"
    Then the output of gtd "next --json=skills" contains "\"my-org-runbook\""
    And the output of gtd "next --json=skills" does not contain "debugging-and-error-recovery"
