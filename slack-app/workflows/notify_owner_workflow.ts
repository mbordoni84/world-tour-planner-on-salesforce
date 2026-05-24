import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { NotifyOwnerStaffingDefinition } from "../functions/notify_owner_staffing.ts";

const NotifyOwnerWorkflow = DefineWorkflow({
  callback_id: "notify_owner_workflow",
  title: "Notify Owner Staffing Change",
  input_parameters: {
    properties: {
      owner_email: { type: Schema.types.string },
      session_name: { type: Schema.types.string },
      changed_user_name: { type: Schema.types.string },
      shift_time: { type: Schema.types.string },
      change_type: { type: Schema.types.string },
      shifts: { type: Schema.types.string },
    },
    required: ["owner_email", "session_name", "changed_user_name", "shift_time", "change_type", "shifts"],
  },
});

NotifyOwnerWorkflow.addStep(NotifyOwnerStaffingDefinition, {
  owner_email: NotifyOwnerWorkflow.inputs.owner_email,
  session_name: NotifyOwnerWorkflow.inputs.session_name,
  changed_user_name: NotifyOwnerWorkflow.inputs.changed_user_name,
  shift_time: NotifyOwnerWorkflow.inputs.shift_time,
  change_type: NotifyOwnerWorkflow.inputs.change_type,
  shifts: NotifyOwnerWorkflow.inputs.shifts,
});

export default NotifyOwnerWorkflow;
