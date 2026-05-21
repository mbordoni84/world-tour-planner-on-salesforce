import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import RequestAccountWorkflow from "../workflows/request_account_workflow.ts";

const requestAccountTrigger: Trigger<typeof RequestAccountWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "Request Account / Recover Credentials",
  description: "Request a new Salesforce staffing account or recover your username / password",
  workflow: `#/workflows/${RequestAccountWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default requestAccountTrigger;
