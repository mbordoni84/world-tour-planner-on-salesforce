import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { PostChannelDigestDefinition } from "../functions/post_channel_digest.ts";

const DailyDigestWorkflow = DefineWorkflow({
  callback_id: "daily_digest_workflow",
  title: "Daily Staffing Digest",
  input_parameters: {
    properties: {
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["channel_id"],
  },
});

DailyDigestWorkflow.addStep(PostChannelDigestDefinition, {
  channel_id: DailyDigestWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default DailyDigestWorkflow;
