export interface OverlapData {
  userName: string;
  shift1Session: string;
  shift1Time: string;
  shift1SessionType: string;
  shift2Session: string;
  shift2Time: string;
  shift2SessionType: string;
}

export function overlapListBlocks(
  overlaps: OverlapData[],
): Record<string, unknown>[] {
  if (overlaps.length === 0) {
    return [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text:
            ":white_check_mark: *No overlaps found.* Your schedule is clear!",
        },
      },
    ];
  }

  const blocks: Record<string, unknown>[] = [
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:warning: *${overlaps.length} overlap${
          overlaps.length > 1 ? "s" : ""
        } found:*`,
      },
    },
  ];

  for (const overlap of overlaps) {
    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `*${overlap.shift1Session}* (${overlap.shift1Time})\n:arrows_counterclockwise: conflicts with\n*${overlap.shift2Session}* (${overlap.shift2Time})`,
      },
    });
    blocks.push({ type: "divider" });
  }

  return blocks;
}
