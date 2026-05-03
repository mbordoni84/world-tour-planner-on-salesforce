import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import DailyDigestWorkflow from "../workflows/daily_digest_workflow.ts";

const dailyDigestTestTrigger: Trigger<typeof DailyDigestWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Staffing Report",
  description: "Post the staffing overview to channel and personal DMs on demand",
  workflow: `#/workflows/${DailyDigestWorkflow.definition.callback_id}`,
  inputs: {
    channel_id: { value: "C0B1RQLJS81" },
  },
};

export default dailyDigestTestTrigger;
