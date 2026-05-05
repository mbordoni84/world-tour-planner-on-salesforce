import { DefineFunction, Schema, SlackFunction } from "deno-slack-sdk/mod.ts";
import { sfFetch } from "../lib/sf_client.ts";

// APPROVAL_CHANNEL is read from function context env vars (set via `slack env add`)

export const RequestAccountDefinition = DefineFunction({
  callback_id: "request_account",
  title: "Request Account",
  source_file: "functions/request_account.ts",
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

const requestAccount = SlackFunction(
  RequestAccountDefinition,
  async ({ inputs, client, env }) => {
    const APPROVAL_CHANNEL = env["APPROVAL_CHANNEL"] || "";
    const userInfo = await client.users.info({ user: inputs.user_id });
    if (!userInfo.ok || !userInfo.user) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: ":x: Could not retrieve your Slack profile.",
      });
      return { completed: false };
    }

    const email = userInfo.user.profile?.email || "";
    const profileFirstName = userInfo.user.profile?.first_name || "";
    const profileLastName = userInfo.user.profile?.last_name || "";
    const realName = userInfo.user.real_name || "";
    const nameParts = realName.split(" ");
    const firstName = profileFirstName || nameParts[0] || "";
    const lastName = profileLastName || nameParts.slice(1).join(" ") || "";

    if (!email.toLowerCase().endsWith("@salesforce.com")) {
      await client.chat.postEphemeral({
        channel: inputs.channel_id,
        user: inputs.user_id,
        text: `:x: Your Slack email (${email || "not set"}) is not a @salesforce.com address. Only @salesforce.com accounts can be created.`,
      });
      return { completed: false };
    }

    await client.chat.postEphemeral({
      channel: inputs.channel_id,
      user: inputs.user_id,
      blocks: [
        {
          type: "header",
          text: { type: "plain_text", text: "Request Staffing Account" },
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "Fill in your details below and confirm.",
          },
        },
        {
          type: "input",
          block_id: "first_name_block",
          element: {
            type: "plain_text_input",
            action_id: "first_name_input",
            initial_value: firstName,
            placeholder: { type: "plain_text", text: "First Name" },
          },
          label: { type: "plain_text", text: "First Name" },
        },
        {
          type: "input",
          block_id: "last_name_block",
          element: {
            type: "plain_text_input",
            action_id: "last_name_input",
            initial_value: lastName,
            placeholder: { type: "plain_text", text: "Last Name" },
          },
          label: { type: "plain_text", text: "Last Name" },
        },
        {
          type: "section",
          block_id: "email_block",
          text: {
            type: "mrkdwn",
            text: `*Email:* ${email}`,
          },
        },
        {
          type: "actions",
          block_id: `confirm_ctx::${inputs.sf_token_id}::${inputs.user_id}::${APPROVAL_CHANNEL}::${email}`,
          elements: [
            {
              type: "button",
              text: { type: "plain_text", text: "Confirm Request" },
              style: "primary",
              action_id: "submit_request",
              value: "submit",
            },
          ],
        },
      ],
      text: "Request Staffing Account",
    });

    return { completed: false };
  },
).addBlockActionsHandler(
  "submit_request",
  async ({ body, client }) => {
    const blockId = body.actions?.[0]?.block_id || "";
    const parts = blockId.replace("confirm_ctx::", "").split("::");
    const tokenId = parts[0] || "";
    const requesterId = parts[1] || "";
    const approvalChannel = parts[2] || "";
    const email = parts[3] || "";
    const channelId = body.channel?.id || body.container?.channel_id || "";

    const stateValues = body.state?.values || {};
    const firstName = stateValues["first_name_block"]?.["first_name_input"]?.value || "";
    const lastName = stateValues["last_name_block"]?.["last_name_input"]?.value || "";

    if (!firstName.trim() || !lastName.trim()) {
      await client.chat.postEphemeral({
        channel: channelId,
        user: requesterId,
        text: ":x: First name and last name are required.",
      });
      return;
    }


    if (!approvalChannel) {
      await client.chat.postEphemeral({
        channel: channelId,
        user: requesterId,
        text: ":x: Approval channel not configured. Contact your admin.",
      });
      return;
    }

    await client.chat.postMessage({
      channel: approvalChannel,
      blocks: [
        {
          type: "header",
          text: { type: "plain_text", text: "New Account Request" },
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*Requested by:* <@${requesterId}>\n*Name:* ${firstName} ${lastName}\n*Email:* ${email}`,
          },
        },
        {
          type: "actions",
          block_id: `approval_ctx::${tokenId}::${firstName}::${lastName}::${email}::${requesterId}::${approvalChannel}`,
          elements: [
            {
              type: "button",
              text: { type: "plain_text", text: "Approve" },
              style: "primary",
              action_id: "approve_request",
              value: "approve",
            },
            {
              type: "button",
              text: { type: "plain_text", text: "Reject" },
              style: "danger",
              action_id: "reject_request",
              value: "reject",
            },
          ],
        },
      ],
      text: `New account request from ${firstName} ${lastName} (${email})`,
    });

    await client.chat.postEphemeral({
      channel: channelId,
      user: requesterId,
      text: `:white_check_mark: Your request has been submitted! You'll receive a DM when it's approved.`,
    });
  },
).addBlockActionsHandler(
  "approve_request",
  async ({ action: _action, body, client }) => {
    const blockId = body.actions?.[0]?.block_id || "";
    const parts = blockId.replace("approval_ctx::", "").split("::");
    const tokenId = parts[0] || "";
    const firstName = parts[1] || "";
    const lastName = parts[2] || "";
    const email = parts[3] || "";
    const requesterId = parts[4] || "";
    const approvalChannel = parts[5] || "";
    const approverId = body.user.id;
    const channelId = body.channel?.id || "";

    const result = await sfFetch(client, tokenId, "/staffing/user/create", {
      method: "POST",
      body: JSON.stringify({ firstName, lastName, email }),
    });

    if (result.ok) {
      const data = result.data as Record<string, unknown>;
      await client.chat.update({
        channel: channelId,
        ts: body.message?.ts || "",
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: `:white_check_mark: *Approved* by <@${approverId}>\n*Name:* ${firstName} ${lastName}\n*Email:* ${email}\n*Username:* ${data.username}`,
            },
          },
        ],
        text: `Account approved for ${firstName} ${lastName}`,
      });

      await client.chat.postMessage({
        channel: requesterId,
        text: `:tada: Your staffing account has been created!\n*Username:* ${data.username}\n\nCheck your email (${email}) for the password reset link. If you don't receive it within a few minutes, ask for help in <#${approvalChannel}>.`,
      });
    } else {
      const rawData = result.data as Record<string, unknown>;
      const errCode = rawData?.error || "";
      const existingUsername = rawData?.username || "";

      if (errCode === "DUPLICATE_EMAIL" && existingUsername) {
        await client.chat.update({
          channel: channelId,
          ts: body.message?.ts || "",
          blocks: [
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: `:information_source: *Account already exists*\n*Name:* ${firstName} ${lastName}\n*Email:* ${email}\n*Username:* ${existingUsername}`,
              },
            },
          ],
          text: `Account already exists for ${firstName} ${lastName}`,
        });

        await client.chat.postMessage({
          channel: requesterId,
          text: `:wave: You already have a staffing account!\n\n*Username:* ${existingUsername}\n*Login:* https://storm-973b1cdf0acdf3.my.salesforce.com/\n*Forgot password:* https://storm-973b1cdf0acdf3.my.salesforce.com/secur/forgotpassword.jsp?locale=us\n\nFor help, ask in <#${approvalChannel}>.`,
        });
      } else {
        const errMsg = rawData?.message || errCode || JSON.stringify(rawData) || "Unknown error";
        await client.chat.update({
          channel: channelId,
          ts: body.message?.ts || "",
          blocks: [
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: `:x: *Failed to create account*\n*Name:* ${firstName} ${lastName}\n*Email:* ${email}\n*Error:* ${errMsg}`,
              },
            },
          ],
          text: `Account creation failed for ${firstName} ${lastName}`,
        });
      }
    }
  },
).addBlockActionsHandler(
  "reject_request",
  async ({ action: _action, body, client }) => {
    const blockId = body.actions?.[0]?.block_id || "";
    const parts = blockId.replace("approval_ctx::", "").split("::");
    const firstName = parts[1] || "";
    const lastName = parts[2] || "";
    const email = parts[3] || "";
    const requesterId = parts[4] || "";
    const approverId = body.user.id;
    const channelId = body.channel?.id || "";

    await client.chat.update({
      channel: channelId,
      ts: body.message?.ts || "",
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `:no_entry: *Rejected* by <@${approverId}>\n*Name:* ${firstName} ${lastName}\n*Email:* ${email}`,
          },
        },
      ],
      text: `Account rejected for ${firstName} ${lastName}`,
    });

    await client.chat.postMessage({
      channel: requesterId,
      text: `:x: Your staffing account request has been declined. Please contact your event coordinator for more information.`,
    });
  },
);

export default requestAccount;
