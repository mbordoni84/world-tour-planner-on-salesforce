export interface ShiftDetail {
  id: string;
  startTime: string;
  endTime: string;
  isClaimed: boolean;
  assignedUserName?: string;
}

export interface SessionData {
  id: string;
  name: string;
  location: string;
  sessionType: string;
  staffingStatus: string;
  needsStaff: boolean;
  isFrozen: boolean;
  claimedShifts: number;
  totalShifts: number;
  availableShifts: number;
  shifts: ShiftDetail[];
}

export interface MyShiftInfo {
  sessionName: string;
  startTime: string;
  endTime: string;
}

const PAGE_SIZE = 5;

export function sessionListBlocks(
  sessions: SessionData[],
  myShifts?: MyShiftInfo[],
  tokenId?: string,
  page = 0,
  sessionTypeFilter = "all",
): Record<string, unknown>[] {
  const needingStaff = sessions.filter((s) => s.availableShifts > 0 && !s.isFrozen);

  if (needingStaff.length === 0) {
    return [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "_All sessions are fully staffed!_",
        },
      },
    ];
  }

  const sessionTypes = [...new Set(needingStaff.map((s) => s.sessionType).filter(Boolean))].sort();

  const filtered = sessionTypeFilter === "all"
    ? needingStaff
    : needingStaff.filter((s) => s.sessionType === sessionTypeFilter);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages - 1);
  const pageSlice = filtered.slice(safePage * PAGE_SIZE, (safePage + 1) * PAGE_SIZE);

  const mySlotKeys = new Set<string>();
  if (myShifts) {
    for (const s of myShifts) {
      mySlotKeys.add(`${s.sessionName}|${s.startTime}|${s.endTime}`);
    }
  }

  const blocks: Record<string, unknown>[] = [];

  const filterOptions = [
    { text: { type: "plain_text" as const, text: "All Types" }, value: "all" },
    ...sessionTypes.map((t) => ({
      text: { type: "plain_text" as const, text: t },
      value: t,
    })),
  ];

  const stateValue = tokenId ? `${tokenId}::${sessionTypeFilter}::${safePage}` : "";

  blocks.push({
    type: "section",
    block_id: `filter_ctx::${tokenId ?? ""}`,
    text: {
      type: "mrkdwn",
      text: `*Filter by type:*  |  Showing ${filtered.length} session(s)  |  Page ${safePage + 1}/${totalPages}`,
    },
    accessory: {
      type: "static_select",
      action_id: "filter_session_type",
      placeholder: { type: "plain_text", text: "Session Type" },
      options: filterOptions,
      initial_option: filterOptions.find((o) => o.value === sessionTypeFilter) ?? filterOptions[0],
    },
  });

  blocks.push({ type: "divider" });

  for (const session of pageSlice) {
    const unclaimedShifts = session.shifts.filter((s) => {
      if (s.isClaimed) return false;
      if (myShifts) {
        const key = `${session.name}|${s.startTime}|${s.endTime}`;
        if (mySlotKeys.has(key)) return false;
      }
      return true;
    });

    const slotMap = new Map<string, number>();
    for (const s of unclaimedShifts) {
      const key = `${s.startTime}-${s.endTime}`;
      slotMap.set(key, (slotMap.get(key) ?? 0) + 1);
    }

    const slotsText = [...slotMap.entries()]
      .slice(0, 3)
      .map(([slot, count]) => `${slot} (${count} avail.)`)
      .join(", ");

    const alreadyAssigned = myShifts
      ? session.shifts.some((s) =>
        s.isClaimed &&
        mySlotKeys.has(`${session.name}|${s.startTime}|${s.endTime}`)
      )
      : false;

    const assignedNote = alreadyAssigned
      ? "\n:bust_in_silhouette: _You're already assigned here_"
      : "";

    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text: `*${session.name}*\n${session.location ?? "TBD"}  |  _${
          session.sessionType ?? ""
        }_\n${session.staffingStatus}  |  ${unclaimedShifts.length} open${assignedNote}\nSlots: ${
          slotsText || "none available for you"
        }`,
      },
    });

    if (unclaimedShifts.length > 0) {
      const seen = new Set<string>();
      const buttons: Record<string, unknown>[] = [];
      for (const shift of unclaimedShifts) {
        const slotKey = `${shift.startTime}-${shift.endTime}`;
        const count = slotMap.get(slotKey) ?? 0;
        if (!seen.has(slotKey) && buttons.length < 3) {
          seen.add(slotKey);
          buttons.push({
            type: "button",
            text: {
              type: "plain_text",
              text: `Claim ${slotKey} (${count})`,
            },
            action_id: `claim_${buttons.length}_${session.id}`,
            value: tokenId ? `${tokenId}::${shift.id}` : shift.id,
          });
        }
      }
      if (buttons.length > 0) {
        blocks.push({ type: "actions", elements: buttons });
      }
    }

    blocks.push({ type: "divider" });
  }

  if (totalPages > 1) {
    const navButtons: Record<string, unknown>[] = [];
    if (safePage > 0) {
      navButtons.push({
        type: "button",
        text: { type: "plain_text", text: ":arrow_left: Previous" },
        action_id: "page_prev",
        value: stateValue,
      });
    }
    if (safePage < totalPages - 1) {
      navButtons.push({
        type: "button",
        text: { type: "plain_text", text: "Next :arrow_right:" },
        action_id: "page_next",
        value: stateValue,
      });
    }
    if (navButtons.length > 0) {
      blocks.push({ type: "actions", elements: navButtons });
    }
  }

  return blocks;
}

