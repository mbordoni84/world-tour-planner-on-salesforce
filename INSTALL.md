# World Tour Staffing App - Installation Guide

## Prerequisites

- Salesforce CLI (`sf`) v2.130+
- Slack CLI (`slack`) v4.0+
- Deno runtime (installed automatically by Slack CLI)
- Node.js 18+ (for LWC testing/linting)
- A Salesforce org (Developer Edition or scratch org)
- A Slack workspace with admin access (or approval process for managed workspaces)

---

## Part 1: Salesforce Org Setup

### 1.1 Create Scratch Org (optional, for testing)

```bash
cd WTPlanner
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias staffing-app \
  --duration-days 7 \
  --set-default
```

Or use an existing org and set it as default:
```bash
sf config set target-org=<your-org-alias>
```

### 1.2 Deploy All Metadata

```bash
cd WTPlanner
sf project deploy start
```

This deploys:
- Custom objects (Event__c, Session_Type__c, Session__c, Shift__c)
- Apex controllers, REST APIs, triggers, test classes
- LWC components + Aura wrappers
- Permission sets (Staffing_App_Admin, Staffing_App_Employee)
- Lightning app, tabs, flexipages
- Custom labels, remote site settings
- Connected App for Slack OAuth

### 1.3 Assign Admin Permission Set

```bash
sf org assign permset --name Staffing_App_Admin
```

### 1.4 Generate Test Data

```bash
sf apex run --file scripts/generate-data.apex
```

Creates 15 users, 6 session types, sessions, 30 shifts with intentional overlaps.

### 1.5 Open the App

```bash
sf org open
```

Navigate to the **World Tour Staffing** app from the App Launcher.

---

## Part 2: Connected App Configuration

The Connected App `Staffing_Slack_App` is deployed with the metadata. After deploy:

1. Go to **Setup > App Manager**
2. Find "Staffing Slack App" and click the dropdown > **Manage**
3. Note the **Consumer Key** (Client ID) — it should match the one in `slack-app/external_auth/salesforce_provider.ts`
4. Click **Manage Consumer Details** to retrieve the **Consumer Secret** — you'll need this for Slack

**Connected App Details:**
- Callback URL: `https://oauth2.slack.com/external/auth/callback`
- OAuth Scopes: `api`, `refresh_token`
- IP Relaxation: Enforce
- Refresh Token Policy: Valid until revoked

---

## Part 3: Slack App Setup

### 3.1 Install/Create the App on a Workspace

```bash
cd slack-app
slack app install
```

- Select **"Create a new app"** if installing on a new workspace
- Select the target workspace
- If admin approval is required, the CLI will submit a request

### 3.2 Deploy the App

```bash
slack deploy
```

Select the target workspace when prompted.

### 3.3 Add OAuth Client Secret

Use the Consumer Secret from Part 2:

```bash
slack external-auth add-secret \
  --provider salesforce_staffing \
  --secret "<CONSUMER_SECRET>"
```

### 3.4 Create a Service Account (for Request Account workflow)

The "Request Account" workflow needs a service account so users without SF accounts can request one.

Create the service account in Salesforce:
```bash
sf apex run -f scripts/create-service-account.apex
```

Or manually create a User with:
- Profile: System Administrator
- Permission Set: Staffing_App_Admin
- Username: `slack.bot.service@staffingapp.<orgId>.sfdc`

Then connect it to Slack:
```bash
slack external-auth add
```
Select provider `salesforce_staffing` and log in with the service account credentials.

Then assign it to the Request Account workflow:
```bash
slack external-auth select-auth
```
Select workflow `#/workflows/request_account_workflow` > provider `salesforce_staffing` > the service account.

### 3.5 Create Triggers

Run these one at a time:

```bash
slack trigger create --trigger-def triggers/available_trigger.ts
slack trigger create --trigger-def triggers/my_shifts_trigger.ts
slack trigger create --trigger-def triggers/overlaps_trigger.ts
slack trigger create --trigger-def triggers/staffing_digest_trigger.ts
slack trigger create --trigger-def triggers/request_account_trigger.ts
slack trigger create --trigger-def triggers/notify_shift_change_trigger.ts
```

**Important:** The last command (`notify_shift_change_trigger`) outputs a webhook URL. Copy it — you need it for Part 4.

### 3.6 Configure Environment Variables

Set the approval channel for account requests (use a **private channel** where only admins are invited):

```bash
slack env add APPROVAL_CHANNEL <channel_id>
```

### 3.7 Invite the Bot to Channels

The bot needs to be invited to:
- The approval channel (private): `/invite @World Tour Staffing`
- Any private channels where users will run commands

Public channels work without invitation (thanks to `chat:write.public` scope).

---

## Part 4: Connect Webhook (Shift Change Notifications)

### 4.1 Update Custom Label in Salesforce

Take the webhook URL from step 3.5 and update the Custom Label:

**Option A — via metadata:**

Edit `WTPlanner/force-app/main/default/labels/CustomLabels.labels-meta.xml`:
```xml
<value>https://hooks.slack.com/triggers/YOUR_TEAM_ID/YOUR_TRIGGER_ID/YOUR_SECRET</value>
```

Then deploy:
```bash
sf project deploy start --source-dir force-app/main/default/labels
```

**Option B — via Setup UI:**

Go to **Setup > Custom Labels > Slack_Shift_Webhook_URL > Edit** and paste the URL.

### 4.2 Verify Remote Site

The remote site `Slack_Webhook` (https://hooks.slack.com) is deployed with the metadata. Verify it's active in **Setup > Remote Site Settings**.

---

## Part 5: Verify Installation

### Salesforce UI
1. Open the **World Tour Staffing** app
2. Check **Staffing Dashboard** shows KPIs
3. Check **Shift Marketplace** shows sessions
4. Check **Master Roster** shows the matrix view
5. As admin: verify "+ New User" button appears in Marketplace

### Slack Commands
Test each shortcut from a channel:
- **Available Sessions** — shows sessions needing staff
- **My Shifts** — shows your assigned shifts
- **Check Overlaps** — shows scheduling conflicts
- **Staffing Report** — posts digest to channel
- **Request Account** — requests a new SF account (should NOT require OAuth)

### Shift Change Notifications
1. Assign a user to a shift in Salesforce
2. Verify a DM is sent to that user on Slack (matched by email)

---

## Multi-Environment Setup

The app supports multiple Slack environments pointing to the same SF org:

| Environment | Use | Command |
|-------------|-----|---------|
| Local (dev) | `slack run` | Local development with hot reload |
| Staging | `slack deploy` (sandbox workspace) | Pre-production testing |
| Production | `slack deploy` (production workspace) | Live users |

Each environment needs:
- Its own `slack deploy`
- Its own triggers (created separately per environment)
- Its own `APPROVAL_CHANNEL` env var (`slack env add`)
- Its own OAuth secret (`slack external-auth add-secret`)
- Its own service account auth (`slack external-auth select-auth`)

The **webhook URL** in the SF Custom Label can only point to one environment at a time. Update it to match the active environment.

---

## Current App IDs

| Environment | App ID | Workspace |
|-------------|--------|-----------|
| Dev (local) | `A0B1SEUQA1E` | slack-demo-18131 |
| Test (prod) | `A0B1E2W443E` | slack-demo-18131 |
| Staging | `A0B26E63J1W` | salesforce-sandbox2 |
| Production | `A0B15F3SSET` | salesforce (Internal) |

---

## Troubleshooting

### "Requires env access to APPROVAL_CHANNEL"
The `APPROVAL_CHANNEL` must be set via `slack env add`, not in `.env` file. The deployed runtime doesn't have `--allow-env` permission for arbitrary env vars.

### "FORBIDDEN: You do not have access to the Apex class"
Add the Apex class to the appropriate permission set (Admin for `StaffingAPI_CreateUser`, Employee for other API classes).

### "Admin privileges required"
The user making the SF API call needs `Staffing_App_Admin` permission set. For the Request Account workflow, ensure the service account is properly connected via `slack external-auth select-auth`.

### Webhook notifications not arriving
1. Check Custom Label `Slack_Shift_Webhook_URL` has the correct URL
2. Check Remote Site `Slack_Webhook` is active
3. Check the bot is invited to the DM channel (it uses `im:write`)
4. Check `slack activity --tail` for errors

### OAuth "Invalid redirect_uri"
Verify the Connected App callback URL is exactly: `https://oauth2.slack.com/external/auth/callback`

### Function timeout (>10s)
The `resetPassword` call is async (`@future`) to avoid this. If it still times out, check for org-level triggers on User (e.g., `SDO_Tool_SalesforceRewind_User`) that slow down user creation.
