# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

World Tour Staffing App — a Salesforce DX project for managing shift scheduling and staff assignments at event sessions. The SFDX project lives in `WTPlanner/` (API v66.0). All `npm` and `sf` commands run from there.

## Commands

```bash
# Lint & format (from WTPlanner/)
npm run lint                   # ESLint on LWC and Aura JS
npm run prettier               # Format all files (Apex, HTML, CSS, XML, etc.)
npm run prettier:verify        # Check formatting without writing

# Tests
npm run test                   # All LWC Jest tests
npm run test:unit:watch        # Watch mode
npm run test:unit:coverage     # With coverage report

# Single test file
npx sfdx-lwc-jest force-app/main/default/lwc/<component>/__tests__/<component>.test.js

# Deploy / push
sf project deploy start        # Deploy to default org
sf project deploy start --source-dir force-app/main/default/classes/MyClass.cls  # Single file

# Scratch org setup (or run ./test-app.sh for full automated setup)
sf org create scratch --definition-file config/project-scratch-def.json --alias staffing-test --duration-days 7 --set-default
sf project deploy start
sf org assign permset --name Staffing_App_Admin
sf apex run --file scripts/generate-data.apex
sf org open
```

Pre-commit hooks (Husky + lint-staged) run Prettier on staged files and Jest on changed LWC files.

## Data Model

```
Event__c
  └── Session_Type__c (MD → Event__c)
        └── Session__c (Lookup → Session_Type__c, not MD due to 3-level depth limit)
              └── Shift__c (MD → Session__c)
```

- **Shift IS the assignment**: `User__c = null` means unclaimed; populated means assigned. There is no separate assignment object.
- `Has_Overlap__c` on Shift__c is set by the trigger when a user has time-conflicting shifts.
- `Min_Shifts__c` / `Max_Shifts__c` on Session__c define staffing requirements.
- `session_owner__c` on Session__c (lookup to User) — the person responsible for the session.
- Unrelated objects also in the repo (Expedition_Booking__c, Gear_Item__c, Lunar_Explorer__c, etc.) — ignore these.

## Architecture

### Apex (in `force-app/main/default/classes/`)

**Controllers** — all `with sharing`, called via `@AuraEnabled` from LWC:
- `StaffingDashboardController` — summary stats, session list, staffing metrics, leaderboard
- `AdminRosterController` — employee×timeslot matrix view
- `ShiftMarketplaceController` — available shifts grouped by session, claim/drop operations
- `OverlapDashboardController` — admin view of all overlaps, reassignment

**Trigger handler** — `ShiftTriggerHandler` (fired by `ShiftTrigger` on Shift__c after insert/update/delete/undelete). Detects overlaps via `Start1 < End2 AND End1 > Start2` for same user. Bulkified for 200 records. Also sends Slack DM notifications via `@future(callout=true)` webhook when `User__c` changes (assigned/removed). Sends two types of notifications: user notification (Custom Label `Slack_Shift_Webhook_URL`) and owner notification with full staffing recap (Custom Label `Slack_Owner_Webhook_URL`). Owner notification is skipped if the owner is the same person being assigned/removed.

**Invocable actions** (for Agentforce agent, `@InvocableMethod`):
- Core: `AgentAction_ClaimShift`, `AgentAction_DropShift`, `AgentAction_CheckOverlaps`, `AgentAction_GetAvailableSessions`, `AgentAction_GetMyShifts`
- Advanced: `AgentAction_GetAllOverlaps`, `AgentAction_GetSessionStaffing`, `AgentAction_GetStaffingOverview`, `AgentAction_GetMyOwnedSessions`, `AgentAction_GetUserInfo`, `AgentAction_GetEligibleUsersForSlot`, `AgentAction_AdminReassignShift`, `AgentAction_AdminUpdateRecord`, `AgentAction_RecommendShifts`
- Accept/return inner Request/Result classes with `@InvocableVariable` fields
- Fuzzy name search in `GetSessionStaffing` and `GetUserInfo` (handles apostrophes, partial names, word splitting)
- These classes are ONLY used by the Agentforce agent — not by LWC, Slack, or REST APIs

**Test classes**: one per controller + `ShiftTriggerHandlerTest`, `StaffingAgentActionsTest`, `AgentActionsRunAsTest`. `TestDataFactory` creates a full dataset (users, session types, sessions, shifts with intentional overlaps).

### LWC (in `force-app/main/default/lwc/`)

Five components, each wrapped by a corresponding **Aura wrapper** (in `aura/`) for tab navigation:
- `staffingDashboard` — summary cards, datatable with filters, overlap section
- `adminMasterRoster` — employee roster matrix with tooltips
- `shiftMarketplace` — accordion of sessions with claim/release buttons, filters
- `overlapDashboard` — overlap list with admin resolve actions
- `mySchedule` — personal schedule view

All use `@wire` with `cacheable=false` Apex methods for real-time data.

### Permission Sets

- `Staffing_App_Admin` — full CRUD on all staffing objects, ViewAll/ModifyAll
- `Staffing_App_Employee` — read-only on Event/Session_Type/Session; edit only `User__c` and `Comment__c` on Shift__c (for claim/drop). No create/delete on any object.
- `Staffing_Assistant_Access` — grants access to the Agentforce agent panel

### App & Navigation

- App: `World_Tour_Staffing` (Lightning app)
- Home page: `Staffing_Home_Page` flexipage
- Tabs reference Aura wrapper components (not LWC directly)

### Agentforce Agent (in `force-app/main/default/aiAuthoringBundles/Staffing_Assistant/`)

Employee agent using Agent Script (`.agent` file). Published via `sf agent publish authoring-bundle`. 8 subagents:
- `shift_management` — view/claim/drop shifts
- `session_info` — lookup any session or user's staffing info
- `admin_operations` — update/rename records (enforced by FLS, double confirmation required)
- `staffing_overview` — global stats
- `overlap_resolution` — smart conflict resolution with impact analysis
- `team_view` — owner sees their session staff
- `shift_recommendations` — suggests shifts based on urgency + no overlap
- `off_topic` — guardrail

Agent actions run as the logged-in user (employee agent). Write permissions are enforced by Salesforce FLS — no custom permission checks needed. After modifying the `.agent` file: validate → publish → activate.

### Slack App (in `slack-app/`)

Deno-based app on Slack next-gen platform. Manages shifts from Slack via Salesforce REST APIs.

**Slack Environments:**
| Environment | App ID | Workspace | Org ID |
|-------------|--------|-----------|--------|
| **Prod** | `A0B15F3SSET` | `salesforce` | `E7T5PNK3P` |
| Staging | `A0B26E63J1W` | `salesforce-sandbox2` | `E04SQG1CF60` |
| Test | `A0B1E2W443E` | `slack-demo-18131` | `E0AKHGA1ME2` |

Default `slack deploy` should always target **prod** (`--app A0B15F3SSET`) unless explicitly testing. After every deploy, re-bind the system-user token to the `request_account_workflow` (it's the only workflow using `credential_source: "DEVELOPER"`). Run the command non-interactively so it works headless / via agent:

```bash
slack external-auth select-auth \
  --app A0B15F3SSET \
  --workflow "#/workflows/request_account_workflow" \
  --provider salesforce_staffing \
  --external-account "slack.bot.service@staffingapp.00dj9000002fddnmac.sfdc"
```

Symptom when missing: every shortcut click on "Request Account / Recover Credentials" fails immediately with `missing_oauth_token_or_selected_auth` in `slack activity --app A0B15F3SSET` — no Apex log on Salesforce, the request never leaves Slack. The interactive `slack external-auth select-auth --app A0B15F3SSET` (no flags) also works but needs a TTY. To verify the binding without re-running the command, inspect `slack-debug-*.log` for `"selected_auth":{...}` inside the workflow entry returned by `apps.auth.external.list`.

**Functions:** `get_available`, `get_my_shifts`, `check_overlaps`, `render_home`, `claim_shift`, `drop_shift`, `notify_shift_change` (DM to assigned/removed user), `notify_owner_staffing` (DM to session owner with full staffing recap)

**Triggers:** 3 shortcut triggers + 2 webhook triggers (user shift change + owner staffing change)

**External Auth:** `salesforce_staffing` OAuth2 provider → SF Connected App

**Shift Change Notifications:** Salesforce `ShiftTriggerHandler` → `@future` callout → Slack webhook trigger → `notify_shift_change` function → DM to user (looked up by email). Also sends owner notification with full session staffing recap via separate webhook (`Slack_Owner_Webhook_URL` custom label).
