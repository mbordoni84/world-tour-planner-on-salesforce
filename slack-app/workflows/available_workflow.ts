import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { GetAvailableDefinition } from "../functions/get_available.ts";

const AvailableWorkflow = DefineWorkflow({
  callback_id: "available_workflow",
  title: "View Available Sessions",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

AvailableWorkflow.addStep(GetAvailableDefinition, {
  user_id: AvailableWorkflow.inputs.user_id,
  channel_id: AvailableWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default AvailableWorkflow;
