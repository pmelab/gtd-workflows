import { expect, it } from "vitest"
import { CONFIG_SCAFFOLD, testRepo } from "@support/testkit"

it("rests at idle pointing at .gtd/TODO.md, the file a process starts from", async () => {
  const repo = testRepo({ workflow: CONFIG_SCAFFOLD })
  expect(await repo.next()).toMatchObject({ state: "idle", actor: "human", file: ".gtd/TODO.md" })
})
