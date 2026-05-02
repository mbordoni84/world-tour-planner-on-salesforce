import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";

export const DropShiftDefinition = DefineFunction({
  callback_id: "drop_shift",
  title: "Drop Shift",
  source_file: "functions/drop_shift.ts",
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
  DropShiftDefinition,
  async ({ inputs, client }) => {
    const result = await sfFetch(
      client,
      inputs.sf_token_id,
      "/staffing/drop",
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
        text: `:x: Could not drop shift: ${errData.error ?? "Unknown error"}`,
      });
      return { outputs: {} };
    }

    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      text: ":white_check_mark: Shift dropped successfully!",
    });

    return { outputs: {} };
  },
);
