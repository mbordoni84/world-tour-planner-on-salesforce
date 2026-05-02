import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import OverlapsWorkflow from "../workflows/overlaps_workflow.ts";

const overlapsTrigger: Trigger<typeof OverlapsWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Check Overlaps",
  description: "Check if your shifts have time conflicts",
  workflow: `#/workflows/${OverlapsWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default overlapsTrigger;
