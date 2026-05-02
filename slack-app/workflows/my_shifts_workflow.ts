import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { GetMyShiftsDefinition } from "../functions/get_my_shifts.ts";

const MyShiftsWorkflow = DefineWorkflow({
  callback_id: "my_shifts_workflow",
  title: "View My Shifts",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

MyShiftsWorkflow.addStep(GetMyShiftsDefinition, {
  user_id: MyShiftsWorkflow.inputs.user_id,
  channel_id: MyShiftsWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default MyShiftsWorkflow;
