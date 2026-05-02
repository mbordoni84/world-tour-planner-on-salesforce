import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import {
  type MyShiftInfo,
  type SessionData,
  sessionListBlocks,
} from "../views/session_blocks.ts";

export const GetAvailableDefinition = DefineFunction({
  callback_id: "get_available",
  title: "Get Available Sessions",
  source_file: "functions/get_available.ts",
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

async function postSessionList(
  client: Parameters<Parameters<typeof SlackFunction>[1]>[0]["client"],
  tokenId: string,
  userId: string,
  channelId: string,
  headerPrefix?: string,
) {
  const [sessionsResult, myShiftsResult] = await Promise.all([
    sfFetch(client, tokenId, "/staffing/available-sessions"),
    sfFetch(client, tokenId, "/staffing/my-shifts"),
  ]);

  if (!sessionsResult.ok) {
    await client.chat.postEphemeral({
      channel: channelId,
      user: userId,
      text: `Error fetching sessions: ${JSON.stringify(sessionsResult.data)}`,
    });
    return;
  }

  const sessions = sessionsResult.data as unknown as SessionData[];
  const needingStaff = sessions.filter((s) => s.needsStaff);

  const myShifts: MyShiftInfo[] = myShiftsResult.ok
    ? (myShiftsResult.data as unknown as MyShiftInfo[])
    : [];

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
    text: {
      type: "plain_text",
      text: `Sessions Needing Staff (${needingStaff.length})`,
    },
  });
  blocks.push({ type: "divider" });
  blocks.push(...sessionListBlocks(sessions, myShifts, tokenId));

  await client.chat.postEphemeral({
    channel: channelId,
    user: userId,
    blocks,
    text: `${needingStaff.length} session(s) need staff.`,
  });
}

const getAvailable = SlackFunction(
  GetAvailableDefinition,
  async ({ inputs, client }) => {
    await postSessionList(
      client,
      inputs.sf_token_id,
      inputs.user_id,
      inputs.channel_id,
    );
    return { completed: false };
  },
).addBlockActionsHandler(
  /^claim_/,
  async ({ action, body, client }) => {
    const parts = (action.value ?? "").split("::");
    const tokenId = parts[0];
    const shiftId = parts[1];
    const userId = body.user.id;
    const channelId = body.channel?.id ?? body.container?.channel_id ?? "";

    const claimResult = await sfFetch(
      client,
      tokenId,
      "/staffing/claim",
      {
        method: "POST",
        body: JSON.stringify({ shiftId }),
      },
    );

    if (claimResult.ok) {
      const myResult = await sfFetch(client, tokenId, "/staffing/my-shifts");
      const myShifts = myResult.ok
        ? (myResult
          .data as unknown as import("../views/shift_blocks.ts").ShiftData[])
        : [];

      const shiftSummary = myShifts.map((s) =>
        `• *${s.sessionName}* ${s.startTime}-${s.endTime}${
          s.hasOverlap ? " :warning: OVERLAP" : ""
        }`
      ).join("\n");

      await client.chat.postEphemeral({
        channel: channelId,
        user: userId,
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text:
                `:white_check_mark: *Shift claimed!*\n\n*Your Shifts (${myShifts.length}):*\n${
                  shiftSummary || "_None_"
                }`,
            },
          },
        ],
        text: "Shift claimed!",
      });
      return;
    } else {
      const errMsg = (claimResult.data as Record<string, unknown>).error ??
        "Unknown error";
      await postSessionList(
        client,
        tokenId,
        userId,
        channelId,
        `:x: *Could not claim shift:* ${errMsg}. Here's the current list:`,
      );
    }
  },
);

export default getAvailable;
