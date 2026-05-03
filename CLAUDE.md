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
- Unrelated objects also in the repo (Expedition_Booking__c, Gear_Item__c, Lunar_Explorer__c, etc.) — ignore these.

## Architecture

### Apex (in `force-app/main/default/classes/`)

**Controllers** — all `with sharing`, called via `@AuraEnabled` from LWC:
- `StaffingDashboardController` — summary stats, session list, staffing metrics, leaderboard
- `AdminRosterController` — employee×timeslot matrix view
- `ShiftMarketplaceController` — available shifts grouped by session, claim/drop operations
- `OverlapDashboardController` — admin view of all overlaps, reassignment

**Trigger handler** — `ShiftTriggerHandler` (fired by `ShiftTrigger` on Shift__c after insert/update/delete/undelete). Detects overlaps via `Start1 < End2 AND End1 > Start2` for same user. Bulkified for 200 records. Also sends Slack DM notifications via `@future(callout=true)` webhook when `User__c` changes (assigned/removed). Webhook URL stored in Custom Label `Slack_Shift_Webhook_URL`.

**Invocable actions** (for Agentforce / AI agents, `@InvocableMethod`):
- `AgentAction_ClaimShift`, `AgentAction_DropShift`, `AgentAction_CheckOverlaps`, `AgentAction_GetAvailableSessions`, `AgentAction_GetMyShifts`
- Accept/return inner Request/Result classes with `@InvocableVariable` fields
- Handle agent string quirks (e.g., session name with type appended in parentheses)

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

- `Staffing_App_Admin` — full CRUD on all staffing objects
- `Staffing_App_Employee` — read sessions/shifts, manage own shift assignments

### App & Navigation

- App: `World_Tour_Staffing` (Lightning app)
- Home page: `Staffing_Home_Page` flexipage
- Tabs reference Aura wrapper components (not LWC directly)

### Slack App (in `slack-app/`)

Deno-based app on Slack next-gen platform. Manages shifts from Slack via Salesforce REST APIs.

**Slack App IDs:**
| Environment | App ID | Workspace | Notes |
|-------------|--------|-----------|-------|
| Dev (local) | `A0B1SEUQA1E` | `slack-demo-18131` | Used with `slack run` |
| Prod | `A0B1E2W443E` | `slack-demo-18131` | Used with `slack deploy` |
| Staging | `A0B26E63J1W` | `salesforce-sandbox2` | Pending admin approval |

**Functions:** `get_available` (session list with filter/pagination), `get_my_shifts`, `check_overlaps`, `render_home`, `claim_shift`, `drop_shift`, `notify_shift_change` (DM notifications)

**Triggers:** 3 shortcut triggers (My Shifts, Available Sessions, Check Overlaps) + 1 webhook trigger (Shift Change notifications from Salesforce)

**External Auth:** `salesforce_staffing` OAuth2 provider → SF Connected App

**Shift Change Notifications:** Salesforce `ShiftTriggerHandler` → `@future` callout → Slack webhook trigger → `notify_shift_change` function → DM to user (looked up by email). Works for changes from any source (Slack, SF UI, API).
