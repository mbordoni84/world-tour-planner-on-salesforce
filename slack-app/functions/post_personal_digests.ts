import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import { type DigestData, type UserDigestData, personalDigestBlocks } from "../views/digest_blocks.ts";

export const PostPersonalDigestsDefinition = DefineFunction({
  callback_id: "post_personal_digests",
  title: "Post Personal Digests",
  source_file: "functions/post_personal_digests.ts",
  input_parameters: {
    properties: {
      sf_token_id: {
        type: Schema.slack.types.oauth2,
        oauth2_provider_key: "salesforce_staffing",
      },
    },
    required: ["sf_token_id"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  PostPersonalDigestsDefinition,
  async ({ inputs, client }) => {
    const result = await sfFetch(client, inputs.sf_token_id, "/staffing/digest");

    if (!result.ok) {
      console.log(`Digest fetch failed: ${JSON.stringify(result.data)}`);
      return { outputs: {} };
    }

    const data = result.data as unknown as DigestData;

    for (const user of data.userDigests) {
      await sendPersonalDM(client, user);
    }

    return { outputs: {} };
  },
);

async function sendPersonalDM(
  client: Parameters<Parameters<typeof SlackFunction>[1]>[0]["client"],
  user: UserDigestData,
) {
  if (!user.email) return;

  const userLookup = await client.users.lookupByEmail({ email: user.email });
  if (!userLookup.ok || !userLookup.user) return;

  const convo = await client.conversations.open({ users: userLookup.user.id });
  if (!convo.ok || !convo.channel) return;

  const blocks = personalDigestBlocks(user);

  await client.chat.postMessage({
    channel: convo.channel.id,
    blocks,
    text: `Your daily shift summary — ${user.shifts.length} shift(s)`,
  });
}
