#!/bin/bash
echo "🚀 World Tour Staffing App - Quick Test Setup"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Creating scratch org...${NC}"
sf org create scratch --definition-file config/project-scratch-def.json --alias staffing-test --duration-days 7 --set-default

if [ $? -ne 0 ]; then
    echo "❌ Failed to create scratch org. Check if Salesforce CLI is installed."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Deploying code...${NC}"
sf project deploy start

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 3: Assigning admin permissions...${NC}"
sf org assign permset --name Staffing_App_Admin

echo ""
echo -e "${BLUE}Step 4: Generating test data...${NC}"
sf apex run --file scripts/generate-data.apex

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "🌐 Opening Salesforce in your browser..."
echo "   → Click App Launcher (9 dots)"
echo "   → Search for 'World Tour Staffing'"
echo "   → Start testing!"
echo ""

sf org open
