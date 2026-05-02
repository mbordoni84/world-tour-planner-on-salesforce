import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";

export const RenderHomeDefinition = DefineFunction({
  callback_id: "render_home",
  title: "Render App Home",
  source_file: "functions/render_home.ts",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
    },
    required: ["user_id"],
  },
  output_parameters: {
    properties: {},
    required: [],
  },
});

export default SlackFunction(
  RenderHomeDefinition,
  async ({ inputs, client }) => {
    await client.views.publish({
      user_id: inputs.user_id,
      view: {
        type: "home",
        blocks: [
          {
            type: "header",
            text: { type: "plain_text", text: "World Tour Staffing" },
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text:
                "Welcome! Use the shortcuts below to manage your event shifts directly from Slack.",
            },
          },
          { type: "divider" },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text:
                ":calendar: *My Shifts*\nView your assigned shifts and drop any you can no longer attend.",
            },
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text:
                ":raising_hand: *Available Sessions*\nBrowse sessions that need staff and claim open shifts.",
            },
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text:
                ":warning: *Check Overlaps*\nSee if any of your shifts conflict with each other.",
            },
          },
          { type: "divider" },
          {
            type: "context",
            elements: [
              {
                type: "mrkdwn",
                text:
                  "Use the *Shortcuts* menu (lightning bolt icon) or type `/` to access these features. On first use, you'll be asked to connect your Salesforce account.",
              },
            ],
          },
        ],
      },
    });

    return { outputs: {} };
  },
);
