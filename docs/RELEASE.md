# Release Guide — Creating a New Package Version

Run this when you have code changes to ship for a new event.

## Prerequisites

- An active Dev Hub org with Dev Hub + 2GP enabled
- Authenticated via CLI: `sf org login web --set-default-dev-hub --alias my-developer-edition`

## Steps

### 1. Make sure you're on main with clean state

```bash
git checkout main
git pull
npm run lint
npm run test:unit
```

### 2. Create the new package version

```bash
cd WTPlanner
sf package version create \
  --package "World Tour Staffing" \
  --installation-key-bypass \
  --wait 20 \
  --target-dev-hub my-developer-edition
```

This takes ~2-3 minutes. On success it prints:

```
Package Installation URL: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t...
```

### 3. Save the new install URL

The `sfdx-project.json` is updated automatically with the new version alias. Commit it:

```bash
git add WTPlanner/sfdx-project.json
git commit -m "Release package vX.Y.Z"
git push
```

Update the install URL in [../README.md](../README.md) and [INSTALL.md](INSTALL.md).

### 4. Install on the new event org

```bash
sf package install --package <new-04t-id> --target-org <new-event-org> --wait 10
```

## Version history

| Version | Package Version Id | Install URL | Notes |
|---|---|---|---|
| 0.1.0 | `04tJ90000009HYvIAM` | `...p0=04tJ90000009HYvIAM` | Initial packaged release (Dev Hub: prod org) |
| 0.1.0-1 | `04tfj000000KYbpAAG` | `...p0=04tfj000000KYbpAAG` | Add demo data seed script (Dev Hub: permanent DE) |

## Dev Hub

Currently using: `matteo.bordoni.b78073148571@agentforce.com` (permanent Developer Edition).

Login:
```bash
sf org login web --set-default-dev-hub --alias my-developer-edition --instance-url https://orgfarm-86aafb3005-dev-ed.develop.my.salesforce.com
```

Update `SFDX_AUTH_URL` secret in GitHub Actions when the token expires:
```bash
sf org display --verbose --target-org my-developer-edition
# copy the "Sfdx Auth Url" value → GitHub Settings → Secrets → SFDX_AUTH_URL
```
