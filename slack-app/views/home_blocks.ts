import { type ShiftData, shiftListBlocks } from "./shift_blocks.ts";
import { type SessionData, sessionListBlocks } from "./session_blocks.ts";

export function homeTabBlocks(
  myShifts: ShiftData[],
  sessions: SessionData[],
): Record<string, unknown>[] {
  const hasOverlaps = myShifts.some((s) => s.hasOverlap);
  const overlapCount = myShifts.filter((s) => s.hasOverlap).length;

  const blocks: Record<string, unknown>[] = [
    {
      type: "header",
      text: { type: "plain_text", text: "World Tour Staffing" },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `*Your Shifts (${myShifts.length})*`,
      },
      accessory: {
        type: "button",
        text: { type: "plain_text", text: "Refresh" },
        action_id: "refresh_home",
      },
    },
    { type: "divider" },
    ...shiftListBlocks(myShifts, true),
  ];

  if (hasOverlaps) {
    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:warning: *You have ${overlapCount} overlapping shift${
          overlapCount > 1 ? "s" : ""
        }* — check your schedule.`,
      },
    });
    blocks.push({ type: "divider" });
  }

  blocks.push({
    type: "header",
    text: { type: "plain_text", text: "Sessions Needing Staff" },
  });

  blocks.push(...sessionListBlocks(sessions, myShifts));

  return blocks;
}
