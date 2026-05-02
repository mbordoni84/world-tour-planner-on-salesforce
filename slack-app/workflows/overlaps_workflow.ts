import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { CheckOverlapsDefinition } from "../functions/check_overlaps.ts";

const OverlapsWorkflow = DefineWorkflow({
  callback_id: "overlaps_workflow",
  title: "Check Overlaps",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
    },
    required: ["user_id", "channel_id"],
  },
});

OverlapsWorkflow.addStep(CheckOverlapsDefinition, {
  user_id: OverlapsWorkflow.inputs.user_id,
  channel_id: OverlapsWorkflow.inputs.channel_id,
  sf_token_id: {
    credential_source: "END_USER",
  },
});

export default OverlapsWorkflow;
