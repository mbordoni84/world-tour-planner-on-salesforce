# Release Guide — Creating a New Package Version

Run this when you have code changes to ship for a new event.

## Prerequisites

- An active Dev Hub org with Dev Hub + 2GP enabled
- Authenticated via CLI: `sf org login web --set-default-dev-hub --alias devhub-permanent`

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
  --target-dev-hub devhub-permanent
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

| Version | Package Version Id | Notes |
|---|---|---|
| 0.1.0 | `04tJ90000009HYvIAM` | Initial packaged release |

## Dev Hub

Currently using: `storm.973b1cdf0acdf3@salesforce.com` (prod org — will expire).

**Before the prod org expires**, re-create the package on your permanent Developer Edition:
1. `sf org login web --set-default-dev-hub --alias devhub-permanent --instance-url https://login.salesforce.com`
2. Enable Dev Hub + 2GP in that org's Setup
3. `sf package create --name "World Tour Staffing" --package-type Unlocked --path force-app --no-namespace --target-dev-hub devhub-permanent`
4. `sf package version create ...` as above
5. Update `SFDX_AUTH_URL` secret in GitHub Actions
