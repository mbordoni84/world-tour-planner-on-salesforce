# Slack Integration Setup

The Slack integration is optional. Without it, the app works fully — users just don't receive DM notifications when shifts change.

## How it works

```
Salesforce ShiftTrigger → Staffing_Setting__mdt → @future callout → Slack webhook → DM to user
```

Two types of notifications:
- **User notification** — DM to the staff member when they are assigned or removed from a shift
- **Owner notification** — DM to the session owner with a full staffing recap

## Prerequisites

- A Slack workspace where the Slack app is deployed
- The `slack-app/` Deno app deployed (see below)
- Two Salesforce webhook trigger URLs from the Slack app

## Steps

### 1. Deploy the Slack app

```bash
cd slack-app
slack deploy --app A0B15F3SSET
```

After every deploy, re-bind the system-user token:
```bash
slack external-auth select-auth \
  --app A0B15F3SSET \
  --workflow "#/workflows/request_account_workflow" \
  --provider salesforce_staffing \
  --external-account "slack.bot.service@staffingapp.00dj9000002fddnmac.sfdc"
```

### 2. Get the webhook URLs from Slack

In the Slack app manifest or triggers output, find the webhook URLs for:
- `shift_change_trigger` → user shift notification
- `owner_staffing_trigger` → owner recap notification

### 3. Configure the Salesforce org

1. Setup → Custom Metadata Types → **Staffing Setting** → Manage Records → **Default**
2. Set **Slack Notifications Enabled** = `true`
3. Set **Slack Shift Webhook URL** = the user notification webhook URL
4. Set **Slack Owner Webhook URL** = the owner recap webhook URL
5. Save

### 4. Add the Slack endpoint to Remote Site Settings

Setup → Remote Site Settings → New:
- Name: `Slack_Webhooks`
- URL: `https://hooks.slack.com`
- Active: ✓

### 5. Test

Assign a shift to a user — they should receive a Slack DM within a few seconds.

## Disabling Slack

Set **Slack Notifications Enabled** = `false` in the Default metadata record. No callouts will be made.
