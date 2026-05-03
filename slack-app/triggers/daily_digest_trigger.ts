import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerTypes } from "deno-slack-api/mod.ts";
import DailyDigestWorkflow from "../workflows/daily_digest_workflow.ts";

const dailyDigestTrigger: Trigger<typeof DailyDigestWorkflow.definition> = {
  type: TriggerTypes.Scheduled,
  name: "Daily Staffing Digest",
  description: "Posts staffing overview to channel and personal DMs every weekday at 08:00",
  workflow: `#/workflows/${DailyDigestWorkflow.definition.callback_id}`,
  inputs: {
    channel_id: { value: "C0B1RQLJS81" },
  },
  schedule: {
    start_time: "2026-05-05T06:00:00Z",
    frequency: {
      type: "weekly",
      repeats_every: 1,
      on_days: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    },
  },
};

export default dailyDigestTrigger;
