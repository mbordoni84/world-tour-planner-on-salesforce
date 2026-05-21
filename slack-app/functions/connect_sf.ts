import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";

const EXPECTED_INSTANCE = "storm-973b1cdf0acdf3";

export const ConnectSfDefinition = DefineFunction({
  callback_id: "connect_sf",
  title: "Connect Salesforce",
  source_file: "functions/connect_sf.ts",
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
  ConnectSfDefinition,
  async ({ inputs, client }) => {
    const tokenResp = await client.apps.auth.external.get({
      external_token_id: inputs.sf_token_id,
    });

    if (!tokenResp.ok || !tokenResp.external_token) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: ":x: Could not retrieve Salesforce token. Please try again.",
      });
      return { outputs: {} };
    }

    let username = "";
    let instanceUrl = "";
    try {
      const infoResp = await fetch(
        "https://login.salesforce.com/services/oauth2/userinfo",
        { headers: { Authorization: `Bearer ${tokenResp.external_token}` } },
      );
      if (infoResp.ok) {
        const info = await infoResp.json() as Record<string, unknown>;
        username = (info.preferred_username ?? info.email ?? "") as string;
        const profile = (info.profile ?? "") as string;
        instanceUrl = profile ? new URL(profile).hostname : "";
      }
    } catch {
      // userinfo non disponibile, continua senza
    }

    const isWrongOrg = instanceUrl !== "" &&
      !instanceUrl.includes(EXPECTED_INSTANCE);

    let text: string;
    if (!username) {
      text = ":white_check_mark: Connected to Salesforce successfully.";
    } else if (isWrongOrg) {
      text =
        `:warning: *Wrong org connected!*\nYou are logged in as \`${username}\` on \`${instanceUrl}\`.\nPlease use *Disconnect Salesforce* and reconnect with your *World Tour org* account (\`${EXPECTED_INSTANCE}\`).`;
    } else {
      text =
        `:white_check_mark: *Connected to Salesforce*\nLogged in as \`${username}\``;
    }

    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      text,
    });

    return { outputs: {} };
  },
);
