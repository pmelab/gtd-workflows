import { describe, expect, it } from "vitest"
import { testRepo } from "@support/testkit"
import { CONFIG_SCAFFOLD } from "@support/testkit"
import { reviewDoc } from "../shared/config.fixture.js"

const REVIEW = ".gtd/REVIEW.md"
const ORIG = ".gtd/REVIEW.orig.md"

describe("the review workflow", () => {
  it("refuses a pending hand-off before requesting any step, the gate's check included", async () => {
    const repo = testRepo({
      workflow: CONFIG_SCAFFOLD,
      files: { [REVIEW]: reviewDoc("note"), [ORIG]: reviewDoc("orig") },
    })
    await expect(repo.door("review")).rejects.toThrow(".gtd/REVIEW.orig.md is a pending hand-off")
    expect(repo.subjects()).toEqual(["chore: initial commit"])
  })
})
