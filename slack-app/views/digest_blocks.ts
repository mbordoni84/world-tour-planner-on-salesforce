interface SummaryData {
  totalShifts: number;
  assigned: number;
  unassigned: number;
  fillRate: number;
  overlaps: number;
}

interface TypeStatsData {
  sessionType: string;
  totalShifts: number;
  assigned: number;
  unassigned: number;
  fillRate: number;
}

interface SessionNeedingStaff {
  name: string;
  sessionType: string;
  claimed: number;
  minShifts: number;
  open: number;
}

interface LeaderboardEntry {
  rank: number;
  userName: string;
  shiftCount: number;
}

interface OverlapEntry {
  userName: string;
  session1: string;
  time1: string;
  session2: string;
  time2: string;
}

export interface DigestData {
  summary: SummaryData;
  bySessionType: TypeStatsData[];
  sessionsNeedingStaff: SessionNeedingStaff[];
  leaderboard: LeaderboardEntry[];
  overlaps: OverlapEntry[];
  userDigests: UserDigestData[];
}

export interface UserDigestData {
  email: string;
  userName: string;
  shifts: { sessionName: string; sessionType: string; startTime: string; endTime: string }[];
  overlaps: { session1: string; time1: string; session2: string; time2: string }[];
}

export function channelDigestBlocks(data: DigestData): Record<string, unknown>[] {
  const blocks: Record<string, unknown>[] = [];
  const today = new Date().toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" });

  blocks.push({
    type: "header",
    text: { type: "plain_text", text: `:bar_chart: Daily Staffing Report — ${today}` },
  });

  const s = data.summary;
  const fillEmoji = s.fillRate >= 80 ? ":large_green_circle:" : s.fillRate >= 50 ? ":large_yellow_circle:" : ":red_circle:";
  blocks.push({
    type: "section",
    text: {
      type: "mrkdwn",
      text: `*Total:* ${s.totalShifts} shifts  |  :white_check_mark: ${s.assigned} assigned  |  :white_large_square: ${s.unassigned} open  |  ${fillEmoji} ${s.fillRate}% fill  |  :warning: ${s.overlaps} overlaps`,
    },
  });

  blocks.push({ type: "divider" });

  const typeLines = data.bySessionType.map((t) => {
    const emoji = t.fillRate >= 80 ? ":white_check_mark:" : t.fillRate >= 50 ? ":warning:" : ":red_circle:";
    return `• *${t.sessionType}* — ${t.assigned}/${t.totalShifts} (${t.fillRate}%) ${emoji}`;
  }).join("\n");

  blocks.push({
    type: "section",
    text: { type: "mrkdwn", text: `:clipboard: *Staffing by Session Type:*\n${typeLines}` },
  });

  blocks.push({ type: "divider" });

  if (data.sessionsNeedingStaff.length > 0) {
    const sessionLines = data.sessionsNeedingStaff.slice(0, 10).map((s) =>
      `• ${s.name} (_${s.sessionType}_) — ${s.claimed}/${s.minShifts} filled, ${s.open} open`
    ).join("\n");

    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:warning: *Sessions Needing Staff (${data.sessionsNeedingStaff.length}):*\n${sessionLines}`,
      },
    });
  } else {
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: ":white_check_mark: *All sessions are fully staffed!*" },
    });
  }

  blocks.push({ type: "divider" });

  const medals = [":first_place_medal:", ":second_place_medal:", ":third_place_medal:"];
  const leaderLines = data.leaderboard.slice(0, 5).map((l) => {
    const prefix = l.rank <= 3 ? medals[l.rank - 1] : `${l.rank}.`;
    return `${prefix} ${l.userName} — ${l.shiftCount} shifts`;
  }).join("\n");

  blocks.push({
    type: "section",
    text: { type: "mrkdwn", text: `:trophy: *Top Contributors:*\n${leaderLines || "_No assignments yet_"}` },
  });

  if (data.overlaps.length > 0) {
    blocks.push({ type: "divider" });

    const overlapLines = data.overlaps.slice(0, 10).map((o) =>
      `• ${o.userName}: ${o.session1} ${o.time1} ↔ ${o.session2} ${o.time2}`
    ).join("\n");

    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:red_circle: *Active Overlaps (${data.overlaps.length}):*\n${overlapLines}`,
      },
    });
  }

  return blocks;
}

export function personalDigestBlocks(user: UserDigestData): Record<string, unknown>[] {
  const blocks: Record<string, unknown>[] = [];
  const today = new Date().toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" });

  blocks.push({
    type: "header",
    text: { type: "plain_text", text: `:calendar: Your Shifts — ${today}` },
  });

  if (user.shifts.length === 0) {
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: "_You have no shifts assigned._" },
    });
    return blocks;
  }

  const shiftLines = user.shifts.map((s) =>
    `• *${s.sessionName}* (_${s.sessionType}_) — ${s.startTime}-${s.endTime}`
  ).join("\n");

  blocks.push({
    type: "section",
    text: { type: "mrkdwn", text: shiftLines },
  });

  if (user.overlaps.length > 0) {
    blocks.push({ type: "divider" });

    const overlapLines = user.overlaps.map((o) =>
      `• ${o.session1} ${o.time1} ↔ ${o.session2} ${o.time2}`
    ).join("\n");

    blocks.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:warning: *You have ${user.overlaps.length} overlap(s):*\n${overlapLines}`,
      },
    });
  }

  return blocks;
}
