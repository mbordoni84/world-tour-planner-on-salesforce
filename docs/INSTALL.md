# Install Guide — New Event Org

Steps to set up the World Tour Staffing app on a fresh org for a new event.

## 1. Install the package

Via browser (recommended for first install):
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tfj000000KYbpAAG
```

Choose **"Install for All Users"** when prompted.

Via CLI:
```bash
sf package install --package 04tfj000000KYbpAAG --target-org <alias> --wait 10
```

## 2. Assign permission sets

Every user needs a permission set. Run from CLI or do it manually in Setup.

```bash
# Admin users
sf org assign permset --name Staffing_App_Admin --target-org <alias>

# Staff/employees
sf org assign permset --name Staffing_App_Employee --target-org <alias>
```

## 3. Create the Event and Session structure

The app ships with no data. Create records in this order:

1. **Event__c** — one record per main event (e.g. "World Tour Milan 2026")
2. **Session_Type__c** — categories (e.g. "Booth", "Stage", "Registration")
3. **Session__c** — individual sessions linked to a Session Type
4. **Shift__c** — time slots within each session (leave `User__c` blank = unclaimed)

Or run a seed script:

```bash
# Realistic World Tour dataset (sessions + shifts, no users)
sf apex run --file WTPlanner/scripts/apex/seed-demo-data.apex --target-org <alias>

# Or: synthetic test dataset (15 users, sessions, 30 shifts with overlaps)
sf apex run --file WTPlanner/scripts/generate-data.apex --target-org <alias>
```

## 4. Open the app

```bash
sf org open --target-org <alias>
```

Navigate to the **World Tour Staffing** app from the App Launcher.

## 5. (Optional) Enable Slack notifications

See [SLACK_SETUP.md](SLACK_SETUP.md).

## 6. (Optional) Configure email domain restriction

If you want to restrict user creation to a specific email domain (e.g. `salesforce.com`):

1. Setup → Custom Metadata Types → **Staffing Setting** → Manage Records → Default
2. Set **Allowed Email Domain** to `salesforce.com` (without `@`)
3. Leave blank to allow any domain
