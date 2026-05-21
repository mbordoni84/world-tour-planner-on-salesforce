import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { DisconnectSfDefinition } from "../functions/disconnect_sf.ts";

const DisconnectWorkflow = DefineWorkflow({
  callback_id: "disconnect_workflow",
  title: "Disconnect Salesforce",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

DisconnectWorkflow.addStep(DisconnectSfDefinition, {
  user_id: DisconnectWorkflow.inputs.user_id,
  channel_id: DisconnectWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default DisconnectWorkflow;
