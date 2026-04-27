#!/bin/bash

# Get access token and instance URL
AUTH_INFO=$(sf org display --target-org admin@event-staffing-app.com --json)
ACCESS_TOKEN=$(echo $AUTH_INFO | jq -r '.result.accessToken')
INSTANCE_URL=$(echo $AUTH_INFO | jq -r '.result.instanceUrl')

echo "Creating tabs via Tooling API..."

# Create Shift Marketplace tab
curl -X POST "${INSTANCE_URL}/services/data/v66.0/tooling/sobjects/CustomTab" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "Label": "Shift Marketplace",
    "Name": "Shift_Marketplace",
    "Motif": "Custom85:Clock",
    "Type": "lightning_component",
    "LightningComponentTabId": "c:ShiftMarketplacePage"
  }'

echo -e "\n\nCreating My Schedule tab..."

# Create My Schedule tab
curl -X POST "${INSTANCE_URL}/services/data/v66.0/tooling/sobjects/CustomTab" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "Label": "My Schedule",
    "Name": "My_Schedule",
    "Motif": "Custom4:Calendar",
    "Type": "lightning_component",
    "LightningComponentTabId": "c:MySchedulePage"
  }'

echo -e "\n\nCreating Overlap Dashboard tab..."

# Create Overlap Dashboard tab
curl -X POST "${INSTANCE_URL}/services/data/v66.0/tooling/sobjects/CustomTab" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "Label": "Overlap Dashboard",
    "Name": "Overlap_Dashboard",
    "Motif": "Custom38:Alert",
    "Type": "lightning_component",
    "LightningComponentTabId": "c:OverlapDashboardPage"
  }'

echo -e "\n\nCreating Master Roster tab..."

# Create Master Roster tab
curl -X POST "${INSTANCE_URL}/services/data/v66.0/tooling/sobjects/CustomTab" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "Label": "Master Roster",
    "Name": "Master_Roster",
    "Motif": "Custom28:People",
    "Type": "lightning_component",
    "LightningComponentTabId": "c:AdminMasterRosterPage"
  }'

echo -e "\n\nDone!"
