import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import ConnectWorkflow from "../workflows/connect_workflow.ts";

const connectTrigger: Trigger<typeof ConnectWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Connect Salesforce",
  description: "Connect or verify your Salesforce account",
  workflow: `#/workflows/${ConnectWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default connectTrigger;
