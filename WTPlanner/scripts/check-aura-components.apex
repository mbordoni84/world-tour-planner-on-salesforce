// Check if Aura components exist in the org
List<AuraDefinition> auraDefs = [
    SELECT AuraDefinitionBundleId, AuraDefinitionBundle.DeveloperName, DefType
    FROM AuraDefinition
    WHERE AuraDefinitionBundle.DeveloperName IN (
        'ShiftMarketplacePage',
        'MySchedulePage',
        'OverlapDashboardPage',
        'AdminMasterRosterPage'
    )
];

System.debug('=== Aura Components Found ===');
Set<String> foundBundles = new Set<String>();
for (AuraDefinition def : auraDefs) {
    if (!foundBundles.contains(def.AuraDefinitionBundle.DeveloperName)) {
        System.debug('✓ ' + def.AuraDefinitionBundle.DeveloperName);
        foundBundles.add(def.AuraDefinitionBundle.DeveloperName);
    }
}

System.debug('\n=== Expected Components ===');
List<String> expected = new List<String>{
    'ShiftMarketplacePage',
    'MySchedulePage',
    'OverlapDashboardPage',
    'AdminMasterRosterPage'
};

for (String comp : expected) {
    if (!foundBundles.contains(comp)) {
        System.debug('✗ MISSING: ' + comp);
    }
}

System.debug('\nTotal found: ' + foundBundles.size() + ' / ' + expected.size());
