import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerTypes } from "deno-slack-api/mod.ts";
import NotifyShiftChangeWorkflow from "../workflows/notify_shift_change_workflow.ts";

const notifyShiftChangeTrigger: Trigger<typeof NotifyShiftChangeWorkflow.definition> = {
  type: TriggerTypes.Webhook,
  name: "Shift Change Webhook",
  description: "Receives shift assignment changes from Salesforce",
  workflow: `#/workflows/${NotifyShiftChangeWorkflow.definition.callback_id}`,
  inputs: {
    user_email: { value: "{{data.user_email}}" },
    session_name: { value: "{{data.session_name}}" },
    shift_time: { value: "{{data.shift_time}}" },
    change_type: { value: "{{data.change_type}}" },
  },
};

export default notifyShiftChangeTrigger;
