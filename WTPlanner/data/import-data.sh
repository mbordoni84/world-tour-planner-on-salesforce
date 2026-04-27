#!/bin/bash

# Lunar Basecamp Outfitters - Sample Data Import Script
# This script imports all sample data in the correct order

echo "🌙 Lunar Basecamp Outfitters - Data Import"
echo "==========================================="
echo ""

# Check if sf CLI is available
if ! command -v sf &> /dev/null
then
    echo "❌ Error: Salesforce CLI (sf) is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "lunar-basecamp-data-plan.json" ]; then
    echo "❌ Error: lunar-basecamp-data-plan.json not found"
    echo "Please run this script from the data directory"
    exit 1
fi

echo "📦 Importing sample data using data plan..."
echo ""

# Import data using the plan file
sf data import tree --plan lunar-basecamp-data-plan.json

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Data import completed successfully!"
    echo ""
    echo "📊 Imported records:"
    echo "   - 5 Lunar Explorers"
    echo "   - 15 Gear Items"
    echo "   - 8 Expedition Bookings"
    echo "   - 12 Safety Certifications"
    echo "   - 14 Expedition Gear assignments"
    echo ""
    echo "🚀 Ready to explore the lunar surface!"
else
    echo ""
    echo "❌ Data import failed. Please check the error messages above."
    exit 1
fi
