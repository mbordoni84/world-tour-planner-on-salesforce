import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import { type ShiftData, shiftListBlocks } from "../views/shift_blocks.ts";

export const GetMyShiftsDefinition = DefineFunction({
  callback_id: "get_my_shifts",
  title: "Get My Shifts",
  source_file: "functions/get_my_shifts.ts",
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

async function postShiftList(
  client: Parameters<Parameters<typeof SlackFunction>[1]>[0]["client"],
  tokenId: string,
  userId: string,
  channelId: string,
  headerPrefix?: string,
) {
  const result = await sfFetch(client, tokenId, "/staffing/my-shifts");

  if (!result.ok) {
    await client.chat.postEphemeral({
      channel: channelId,
      user: userId,
      text: `Error fetching shifts: ${JSON.stringify(result.data)}`,
    });
    return;
  }

  const shifts = result.data as unknown as ShiftData[];

  const blocks: Record<string, unknown>[] = [];

  if (headerPrefix) {
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: headerPrefix },
    });
    blocks.push({ type: "divider" });
  }

  blocks.push({
    type: "header",
    text: { type: "plain_text", text: `Your Shifts (${shifts.length})` },
  });
  blocks.push({ type: "divider" });
  blocks.push(...shiftListBlocks(shifts, true, tokenId));

  await client.chat.postEphemeral({
    channel: channelId,
    user: userId,
    blocks,
    text: `You have ${shifts.length} shift(s) assigned.`,
  });
}

const getMyShifts = SlackFunction(
  GetMyShiftsDefinition,
  async ({ inputs, client }) => {
    await postShiftList(
      client,
      inputs.sf_token_id,
      inputs.user_id,
      inputs.channel_id,
    );
    return { completed: false };
  },
).addBlockActionsHandler(
  /^drop_shift$/,
  async ({ action, body, client }) => {
    const parts = (action.value ?? "").split("::");
    const tokenId = parts[0];
    const shiftId = parts[1];
    const userId = body.user.id;
    const channelId = body.channel?.id ?? body.container?.channel_id ?? "";

    const dropResult = await sfFetch(
      client,
      tokenId,
      "/staffing/drop",
      {
        method: "POST",
        body: JSON.stringify({ shiftId }),
      },
    );

    if (dropResult.ok) {
      await postShiftList(
        client,
        tokenId,
        userId,
        channelId,
        ":white_check_mark: *Shift dropped!* Here's your updated schedule:",
      );
    } else {
      const errMsg = (dropResult.data as Record<string, unknown>).error ??
        "Unknown error";
      await postShiftList(
        client,
        tokenId,
        userId,
        channelId,
        `:x: *Could not drop shift:* ${errMsg}. Here's your current schedule:`,
      );
    }
  },
);

export default getMyShifts;
