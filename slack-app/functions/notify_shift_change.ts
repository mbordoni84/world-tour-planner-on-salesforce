import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";

export const NotifyShiftChangeDefinition = DefineFunction({
  callback_id: "notify_shift_change",
  title: "Notify Shift Change",
  source_file: "functions/notify_shift_change.ts",
  input_parameters: {
    properties: {
      user_email: { type: Schema.types.string, description: "Salesforce user email" },
      session_name: { type: Schema.types.string, description: "Session name" },
      shift_time: { type: Schema.types.string, description: "Shift time range" },
      change_type: { type: Schema.types.string, description: "assigned or removed" },
    },
    required: ["user_email", "session_name", "shift_time", "change_type"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  NotifyShiftChangeDefinition,
  async ({ inputs, client }) => {
    const { user_email, session_name, shift_time, change_type } = inputs;

    const userLookup = await client.users.lookupByEmail({ email: user_email });
    if (!userLookup.ok || !userLookup.user) {
      console.log(`Could not find Slack user for email: ${user_email}`);
      return { outputs: {} };
    }

    const slackUserId = userLookup.user.id;

    const convo = await client.conversations.open({ users: slackUserId });
    if (!convo.ok || !convo.channel) {
      console.log(`Could not open DM with user: ${slackUserId}`);
      return { outputs: {} };
    }

    const dmChannelId = convo.channel.id;

    const emoji = change_type === "assigned" ? ":white_check_mark:" : ":x:";
    const verb = change_type === "assigned" ? "assigned to" : "removed from";
    const text = `${emoji} You have been *${verb}* a shift:\n\n*Session:* ${session_name}\n*Time:* ${shift_time}`;

    await client.chat.postMessage({
      channel: dmChannelId,
      text,
      blocks: [
        {
          type: "section",
          text: { type: "mrkdwn", text },
        },
      ],
    });

    return { outputs: {} };
  },
);
