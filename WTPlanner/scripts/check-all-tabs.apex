// Check all custom tabs in the org
List<TabDefinition> allTabs = [
    SELECT Label, SobjectName, IsCustom
    FROM TabDefinition
    WHERE IsCustom = true
    ORDER BY Label
];

System.debug('=== All Custom Tabs in Org ===');
for (TabDefinition tab : allTabs) {
    System.debug('Tab: ' + tab.Label + ' | Object: ' + tab.SobjectName);
}

System.debug('\n=== Looking for LWC tabs ===');
List<String> expectedTabs = new List<String>{
    'Shift Marketplace',
    'My Schedule',
    'Overlap Dashboard',
    'Master Roster'
};

Set<String> foundLabels = new Set<String>();
for (TabDefinition tab : allTabs) {
    foundLabels.add(tab.Label);
}

for (String expected : expectedTabs) {
    if (foundLabels.contains(expected)) {
        System.debug('✓ Found: ' + expected);
    } else {
        System.debug('✗ MISSING: ' + expected);
    }
}
