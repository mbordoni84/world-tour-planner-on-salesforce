import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import { type DigestData, channelDigestBlocks } from "../views/digest_blocks.ts";

export const PostChannelDigestDefinition = DefineFunction({
  callback_id: "post_channel_digest",
  title: "Post Channel Digest",
  source_file: "functions/post_channel_digest.ts",
  input_parameters: {
    properties: {
      channel_id: { type: Schema.slack.types.channel_id },
      sf_token_id: {
        type: Schema.slack.types.oauth2,
        oauth2_provider_key: "salesforce_staffing",
      },
    },
    required: ["channel_id", "sf_token_id"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  PostChannelDigestDefinition,
  async ({ inputs, client }) => {
    const result = await sfFetch(client, inputs.sf_token_id, "/staffing/digest");

    if (!result.ok) {
      console.log(`Digest fetch failed: ${JSON.stringify(result.data)}`);
      return { outputs: {} };
    }

    const data = result.data as unknown as DigestData;
    const blocks = channelDigestBlocks(data);

    await client.chat.postMessage({
      channel: inputs.channel_id,
      blocks,
      text: `Daily Staffing Report — ${data.summary.assigned}/${data.summary.totalShifts} shifts filled (${data.summary.fillRate}%)`,
    });

    return { outputs: {} };
  },
);
