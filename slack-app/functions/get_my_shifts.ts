import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";
import { type ShiftData, shiftListBlocks } from "../views/shift_blocks.ts";

interface OwnedSessionShift {
  startTime: string;
  endTime: string;
  assignedUserName: string | null;
  isClaimed: boolean;
}

interface OwnedSessionData {
  id: string;
  name: string;
  location: string;
  sessionType: string;
  totalShifts: number;
  claimedShifts: number;
  staffingStatus: string;
  isFrozen: boolean;
  shifts: OwnedSessionShift[];
}

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

function ownedSessionBlocks(
  sessions: OwnedSessionData[],
): Record<string, unknown>[] {
  if (sessions.length === 0) return [];

  const blocks: Record<string, unknown>[] = [];

  blocks.push({
    type: "header",
    text: { type: "plain_text", text: `You are owner of the following sessions (${sessions.length})` },
  });
  blocks.push({
    type: "context",
    elements: [
      { type: "mrkdwn", text: ":key: Contatta proattivamente lo staff della tua sessione e assicurati che tutti siano sul pezzo, è compito tuo!" },
    ],
  });
  blocks.push({ type: "divider" });

  for (const session of sessions) {
    const frozen = session.isFrozen ? "  :lock: _Frozen_" : "";

    let shiftLines = "";
    if (session.shifts && session.shifts.length > 0) {
      shiftLines = "\n" + session.shifts.map((s) => {
        if (s.isClaimed && s.assignedUserName) {
          return `:white_check_mark: ${s.startTime} - ${s.endTime} — ${s.assignedUserName}`;
        }
        return `:white_large_square: ${s.startTime} - ${s.endTime} — _Open_`;
      }).join("\n");
    }

    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `*${session.name}*${frozen}\n${session.claimedShifts}/${session.totalShifts} shifts filled  |  ${
            session.location ?? "TBD"
          }  |  _${session.sessionType ?? ""}_${shiftLines}`,
      },
    });
    blocks.push({ type: "divider" });
  }

  return blocks;
}

async function postShiftList(
  client: Parameters<Parameters<typeof SlackFunction>[1]>[0]["client"],
  tokenId: string,
  userId: string,
  channelId: string,
  headerPrefix?: string,
) {
  const [shiftsResult, ownedResult] = await Promise.all([
    sfFetch(client, tokenId, "/staffing/my-shifts"),
    sfFetch(client, tokenId, "/staffing/owned-sessions"),
  ]);

  if (!shiftsResult.ok) {
    await client.chat.postEphemeral({
      channel: channelId,
      user: userId,
      text: `Error fetching shifts: ${JSON.stringify(shiftsResult.data)}`,
    });
    return;
  }

  const shifts = shiftsResult.data as unknown as ShiftData[];
  const ownedSessions = ownedResult.ok
    ? (ownedResult.data as unknown as OwnedSessionData[])
    : [];

  const blocks: Record<string, unknown>[] = [];

  if (headerPrefix) {
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: headerPrefix },
    });
    blocks.push({ type: "divider" });
  }

  if (ownedSessions.length > 0) {
    blocks.push(...ownedSessionBlocks(ownedSessions));
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
