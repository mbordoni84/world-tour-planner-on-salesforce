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

function buildBlocks(
  sessions: SessionData[],
  myShifts: MyShiftInfo[],
  tokenId: string,
  page: number,
  sessionTypeFilter: string,
  headerPrefix?: string,
): { blocks: Record<string, unknown>[]; text: string } {
  const needingStaff = sessions.filter((s) => s.needsStaff);

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
  blocks.push(...sessionListBlocks(sessions, myShifts, tokenId, page, sessionTypeFilter));

  return { blocks, text: `${needingStaff.length} session(s) need staff.` };
}

async function fetchAndBuild(
  client: Parameters<Parameters<typeof SlackFunction>[1]>[0]["client"],
  tokenId: string,
  page: number,
  sessionTypeFilter: string,
  headerPrefix?: string,
): Promise<{ blocks: Record<string, unknown>[]; text: string } | null> {
  const [sessionsResult, myShiftsResult] = await Promise.all([
    sfFetch(client, tokenId, "/staffing/available-sessions"),
    sfFetch(client, tokenId, "/staffing/my-shifts"),
  ]);

  if (!sessionsResult.ok) return null;

  const sessions = sessionsResult.data as unknown as SessionData[];
  const myShifts: MyShiftInfo[] = myShiftsResult.ok
    ? (myShiftsResult.data as unknown as MyShiftInfo[])
    : [];

  return buildBlocks(sessions, myShifts, tokenId, page, sessionTypeFilter, headerPrefix);
}

const getAvailable = SlackFunction(
  GetAvailableDefinition,
  async ({ inputs, client }) => {
    const result = await fetchAndBuild(client, inputs.sf_token_id, 0, "all");
    if (!result) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: "Error fetching sessions from Salesforce.",
      });
      return { completed: false };
    }
    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      blocks: result.blocks,
      text: result.text,
    });
    return { completed: false };
  },
).addBlockActionsHandler(
  "filter_session_type",
  async ({ action, body, client }) => {
    const selectedType = action.selected_option?.value ?? "all";
    const blockId = action.block_id ?? "";
    const tokenId = blockId.startsWith("filter_ctx::") ? blockId.slice("filter_ctx::".length) : "";
    const userId = body.user.id;
    const channelId = body.channel?.id ?? body.container?.channel_id ?? "";

    const result = await fetchAndBuild(client, tokenId, 0, selectedType);
    if (result) {
      await client.chat.postEphemeral({
        channel: channelId,
        user: userId,
        blocks: result.blocks,
        text: result.text,
      });
    }
  },
).addBlockActionsHandler(
  /^page_(prev|next)$/,
  async ({ action, body, client }) => {
    const parts = (action.value ?? "").split("::");
    const tokenId = parts[0] || "";
    const sessionTypeFilter = parts[1] || "all";
    const currentPage = parseInt(parts[2] || "0", 10);
    const userId = body.user.id;
    const channelId = body.channel?.id ?? body.container?.channel_id ?? "";

    const newPage = action.action_id === "page_next" ? currentPage + 1 : currentPage - 1;

    const result = await fetchAndBuild(client, tokenId, Math.max(0, newPage), sessionTypeFilter);
    if (result) {
      await client.chat.postEphemeral({
        channel: channelId,
        user: userId,
        blocks: result.blocks,
        text: result.text,
      });
    }
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
      const result = await fetchAndBuild(
        client,
        tokenId,
        0,
        "all",
        `:x: *Could not claim shift:* ${errMsg}. Here's the current list:`,
      );
      if (result) {
        await client.chat.postEphemeral({
          channel: channelId,
          user: userId,
          blocks: result.blocks,
          text: result.text,
        });
      }
    }
  },
);

export default getAvailable;
