// Check if LWC components exist in the org
List<LightningComponentBundle> lwcs = [
    SELECT Id, DeveloperName, IsExposed, ApiVersion
    FROM LightningComponentBundle
    WHERE DeveloperName IN (
        'shiftMarketplace',
        'mySchedule',
        'overlapDashboard',
        'adminMasterRoster'
    )
];

System.debug('=== LWC Components Found ===');
for (LightningComponentBundle lwc : lwcs) {
    System.debug('✓ ' + lwc.DeveloperName + ' | IsExposed: ' + lwc.IsExposed + ' | API: ' + lwc.ApiVersion);
}

System.debug('\n=== Expected Components ===');
List<String> expected = new List<String>{
    'shiftMarketplace',
    'mySchedule',
    'overlapDashboard',
    'adminMasterRoster'
};

Set<String> found = new Set<String>();
for (LightningComponentBundle lwc : lwcs) {
    found.add(lwc.DeveloperName);
}

for (String comp : expected) {
    if (!found.contains(comp)) {
        System.debug('✗ MISSING: ' + comp);
    }
}

System.debug('\nTotal found: ' + lwcs.size() + ' / ' + expected.size());
