import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { RequestAccountDefinition } from "../functions/request_account.ts";

const RequestAccountWorkflow = DefineWorkflow({
  callback_id: "request_account_workflow",
  title: "Request Staffing Account",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

RequestAccountWorkflow.addStep(RequestAccountDefinition, {
  user_id: RequestAccountWorkflow.inputs.user_id,
  channel_id: RequestAccountWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "DEVELOPER",
  },
});

export default RequestAccountWorkflow;
