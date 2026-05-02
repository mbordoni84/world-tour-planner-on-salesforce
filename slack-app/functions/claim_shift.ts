import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";

export const ClaimShiftDefinition = DefineFunction({
  callback_id: "claim_shift",
  title: "Claim Shift",
  source_file: "functions/claim_shift.ts",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
      shift_id: { type: Schema.types.string },
      sf_token_id: {
        type: Schema.slack.types.oauth2,
        oauth2_provider_key: "salesforce_staffing",
      },
    },
    required: ["user_id", "channel_id", "shift_id", "sf_token_id"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  ClaimShiftDefinition,
  async ({ inputs, client }) => {
    const overlapCheck = await sfFetch(
      client,
      inputs.sf_token_id,
      `/staffing/check-overlap?shiftId=${inputs.shift_id}`,
    );

    let overlapWarning = "";
    if (overlapCheck.ok) {
      const checkData = overlapCheck.data as Record<string, unknown>;
      if (checkData.hasOverlap) {
        overlapWarning = ` :warning: ${checkData.message}`;
      }
    }

    const result = await sfFetch(
      client,
      inputs.sf_token_id,
      "/staffing/claim",
      {
        method: "POST",
        body: JSON.stringify({ shiftId: inputs.shift_id }),
      },
    );

    if (!result.ok) {
      const errData = result.data as Record<string, unknown>;
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: `:x: Could not claim shift: ${errData.error ?? "Unknown error"}`,
      });
      return { outputs: {} };
    }

    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      text: `:white_check_mark: Shift claimed successfully!${overlapWarning}`,
    });

    return { outputs: {} };
  },
);
