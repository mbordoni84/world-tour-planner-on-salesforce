import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import {
  type OverlapData,
  overlapListBlocks,
} from "../views/overlap_blocks.ts";

export const CheckOverlapsDefinition = DefineFunction({
  callback_id: "check_overlaps",
  title: "Check Overlaps",
  source_file: "functions/check_overlaps.ts",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
      channel_id: { type: Schema.slack.types.channel_id },
      sf_token_id: {
        type: Schema.slack.types.oauth2,
        oauth2_provider_key: "salesforce_staffing",
      },
    },
    required: ["user_id", "channel_id", "sf_token_id"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  CheckOverlapsDefinition,
  async ({ inputs, client }) => {
    const result = await sfFetch(
      client,
      inputs.sf_token_id,
      "/staffing/overlaps",
    );

    if (!result.ok) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: `Error checking overlaps: ${JSON.stringify(result.data)}`,
      });
      return { outputs: {} };
    }

    const overlaps = result.data as unknown as OverlapData[];
    const blocks = [
      {
        type: "header",
        text: { type: "plain_text", text: "Overlap Check" },
      },
      { type: "divider" },
      ...overlapListBlocks(overlaps),
    ];

    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      blocks,
      text: overlaps.length === 0
        ? "No overlaps found!"
        : `Found ${overlaps.length} overlap(s).`,
    });

    return { outputs: {} };
  },
);
