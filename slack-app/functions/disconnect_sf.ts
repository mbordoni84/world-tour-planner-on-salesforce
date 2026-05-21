import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";

export const DisconnectSfDefinition = DefineFunction({
  callback_id: "disconnect_sf",
  title: "Disconnect Salesforce",
  source_file: "functions/disconnect_sf.ts",
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

export default SlackFunction(
  DisconnectSfDefinition,
  async ({ inputs, client }) => {
    const result = await client.apps.auth.external.delete({
      external_token_id: inputs.sf_token_id,
    });

    if (result.ok) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: ":white_check_mark: *Disconnected from Salesforce.* Use any shortcut to reconnect — make sure to log in with your *World Tour org* account.",
      });
    } else {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: `:x: Could not disconnect: ${result.error ?? "Unknown error"}`,
      });
    }

    return { outputs: {} };
  },
);
