import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { NotifyShiftChangeDefinition } from "../functions/notify_shift_change.ts";

const NotifyShiftChangeWorkflow = DefineWorkflow({
  callback_id: "notify_shift_change_workflow",
  title: "Notify Shift Change",
  input_parameters: {
    properties: {
      user_email: { type: Schema.types.string },
      session_name: { type: Schema.types.string },
      shift_time: { type: Schema.types.string },
      change_type: { type: Schema.types.string },
    },
    required: ["user_email", "session_name", "shift_time", "change_type"],
  },
});

NotifyShiftChangeWorkflow.addStep(NotifyShiftChangeDefinition, {
  user_email: NotifyShiftChangeWorkflow.inputs.user_email,
  session_name: NotifyShiftChangeWorkflow.inputs.session_name,
  shift_time: NotifyShiftChangeWorkflow.inputs.shift_time,
  change_type: NotifyShiftChangeWorkflow.inputs.change_type,
});

export default NotifyShiftChangeWorkflow;
