import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import AvailableWorkflow from "../workflows/available_workflow.ts";

const availableTrigger: Trigger<typeof AvailableWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Available Sessions",
  description: "View sessions that need staff",
  workflow: `#/workflows/${AvailableWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default availableTrigger;
