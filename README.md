# World Tour Staffing App

Salesforce app for managing shift scheduling and staff assignments at event sessions.

## Features

- **Staffing Dashboard** — KPI cards, session list with fill rates, leaderboard
- **Shift Marketplace** — browse and claim/drop available shifts
- **My Schedule** — personal schedule view with owned-session slot breakdown
- **Admin Master Roster** — employee × timeslot matrix
- **Overlap Dashboard** — detect and resolve scheduling conflicts
- **Freeze Control** — lock sessions/session types to prevent changes
- **Slack Integration** (optional) — DM notifications on shift changes

## Install

Use this URL to install on any Salesforce org:

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ90000009HYvIAM
```

Or via CLI:

```bash
sf package install --package 04tJ90000009HYvIAM --target-org <your-org> --wait 10
```

After install, see [docs/INSTALL.md](docs/INSTALL.md) for post-install setup.

## Repository structure

```
WTPlanner/          # Salesforce DX project (API v66.0)
  force-app/        # Source metadata
  config/           # Scratch org definition
  scripts/          # Data seed scripts
slack-app/          # Optional Slack integration (Deno, separate deploy)
docs/               # Setup and release guides
```

## Development

```bash
cd WTPlanner
npm install
npm run lint
npm run test:unit
```

See [docs/RELEASE.md](docs/RELEASE.md) to create a new package version.
