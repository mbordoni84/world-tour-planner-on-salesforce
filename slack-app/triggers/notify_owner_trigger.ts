import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerTypes } from "deno-slack-api/mod.ts";
import NotifyOwnerWorkflow from "../workflows/notify_owner_workflow.ts";

const notifyOwnerTrigger: Trigger<typeof NotifyOwnerWorkflow.definition> = {
  type: TriggerTypes.Webhook,
  name: "Owner Staffing Change Webhook",
  description: "Receives staffing change notifications for session owners from Salesforce",
  workflow: `#/workflows/${NotifyOwnerWorkflow.definition.callback_id}`,
  inputs: {
    owner_email: { value: "{{data.owner_email}}" },
    session_name: { value: "{{data.session_name}}" },
    changed_user_name: { value: "{{data.changed_user_name}}" },
    shift_time: { value: "{{data.shift_time}}" },
    change_type: { value: "{{data.change_type}}" },
    shifts: { value: "{{data.shifts}}" },
  },
};

export default notifyOwnerTrigger;
