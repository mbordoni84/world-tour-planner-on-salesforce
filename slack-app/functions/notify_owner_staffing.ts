import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";

export const NotifyOwnerStaffingDefinition = DefineFunction({
  callback_id: "notify_owner_staffing",
  title: "Notify Owner Staffing Change",
  source_file: "functions/notify_owner_staffing.ts",
  input_parameters: {
    properties: {
      owner_email: { type: Schema.types.string, description: "Session owner email" },
      session_name: { type: Schema.types.string, description: "Session name" },
      changed_user_name: { type: Schema.types.string, description: "Name of user assigned/removed" },
      shift_time: { type: Schema.types.string, description: "Shift time range" },
      change_type: { type: Schema.types.string, description: "assigned or removed" },
      shifts: { type: Schema.types.string, description: "JSON array of all shifts in the session" },
    },
    required: ["owner_email", "session_name", "changed_user_name", "shift_time", "change_type", "shifts"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

interface ShiftRecap {
  startTime: string;
  endTime: string;
  assignedUserName: string | null;
}

export default SlackFunction(
  NotifyOwnerStaffingDefinition,
  async ({ inputs, client }) => {
    const { owner_email, session_name, changed_user_name, shift_time, change_type, shifts } = inputs;

    const userLookup = await client.users.lookupByEmail({ email: owner_email });
    if (!userLookup.ok || !userLookup.user) {
      console.log(`Could not find Slack user for owner email: ${owner_email}`);
      return { outputs: {} };
    }

    const slackUserId = userLookup.user.id;

    const convo = await client.conversations.open({ users: slackUserId });
    if (!convo.ok || !convo.channel) {
      console.log(`Could not open DM with owner: ${slackUserId}`);
      return { outputs: {} };
    }

    const dmChannelId = convo.channel.id;

    const emoji = change_type === "assigned" ? ":white_check_mark:" : ":x:";
    const verb = change_type === "assigned" ? "has been assigned to" : "has been removed from";
    const changeText = `${emoji} *${changed_user_name}* ${verb} the ${shift_time} shift`;

    let recapText = "";
    try {
      const shiftList: ShiftRecap[] = JSON.parse(shifts);
      const lines = shiftList.map((s) => {
        if (s.assignedUserName) {
          return `:white_check_mark: ${s.startTime} - ${s.endTime} — ${s.assignedUserName}`;
        }
        return `:white_large_square: ${s.startTime} - ${s.endTime} — _Open_`;
      });
      recapText = lines.join("\n");
    } catch {
      recapText = "_Unable to load staffing details_";
    }

    await client.chat.postMessage({
      channel: dmChannelId,
      text: `Staffing Update — ${session_name}: ${changed_user_name} ${verb} the ${shift_time} shift`,
      blocks: [
        {
          type: "header",
          text: { type: "plain_text", text: `Staffing Update — ${session_name}` },
        },
        {
          type: "context",
          elements: [
            { type: "mrkdwn", text: ":clipboard: You are receiving this because you are the owner of this session." },
          ],
        },
        {
          type: "section",
          text: { type: "mrkdwn", text: changeText },
        },
        { type: "divider" },
        {
          type: "section",
          text: { type: "mrkdwn", text: `*Current Staffing:*\n${recapText}` },
        },
      ],
    });

    return { outputs: {} };
  },
);
