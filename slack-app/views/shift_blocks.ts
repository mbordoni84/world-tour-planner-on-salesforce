export interface ShiftData {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  sessionName: string;
  sessionLocation: string;
  sessionType: string;
  hasOverlap: boolean;
}

export function shiftListBlocks(
  shifts: ShiftData[],
  showDropButton = false,
  tokenId?: string,
): Record<string, unknown>[] {
  if (shifts.length === 0) {
    return [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "_You have no shifts assigned._",
        },
      },
    ];
  }

  const blocks: Record<string, unknown>[] = [];

  for (const shift of shifts) {
    const overlap = shift.hasOverlap ? "  :warning: *OVERLAP*" : "";
    const section: Record<string, unknown> = {
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `*${shift.sessionName}*${overlap}\n${shift.startTime} - ${shift.endTime}  |  ${
            shift.sessionLocation ?? "TBD"
          }  |  _${shift.sessionType ?? ""}_`,
      },
    };

    if (showDropButton) {
      section.accessory = {
        type: "button",
        text: { type: "plain_text", text: "Drop" },
        style: "danger",
        action_id: "drop_shift",
        value: tokenId ? `${tokenId}::${shift.id}` : shift.id,
        confirm: {
          title: { type: "plain_text", text: "Drop Shift" },
          text: {
            type: "mrkdwn",
            text:
              `Are you sure you want to drop *${shift.sessionName}* (${shift.startTime} - ${shift.endTime})?`,
          },
          confirm: { type: "plain_text", text: "Drop" },
          deny: { type: "plain_text", text: "Cancel" },
        },
      };
    }

    blocks.push(section);
    blocks.push({ type: "divider" });
  }

  return blocks;
}
