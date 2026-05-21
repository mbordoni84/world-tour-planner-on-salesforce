import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import DisconnectWorkflow from "../workflows/disconnect_workflow.ts";

const disconnectTrigger: Trigger<typeof DisconnectWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Disconnect Salesforce",
  description: "Disconnect your Salesforce account from this app",
  workflow: `#/workflows/${DisconnectWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default disconnectTrigger;
