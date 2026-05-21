import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { ConnectSfDefinition } from "../functions/connect_sf.ts";

const ConnectWorkflow = DefineWorkflow({
  callback_id: "connect_workflow",
  title: "Connect Salesforce",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

ConnectWorkflow.addStep(ConnectSfDefinition, {
  user_id: ConnectWorkflow.inputs.user_id,
  channel_id: ConnectWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default ConnectWorkflow;
