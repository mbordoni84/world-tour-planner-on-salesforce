// Check app configuration type
List<AppDefinition> apps = [
    SELECT DurableId, Label, NavType, UiType
    FROM AppDefinition
    WHERE Label LIKE '%World Tour%' OR Label LIKE '%Staffing%'
];

System.debug('=== App Configuration ===');
for (AppDefinition app : apps) {
    System.debug('App: ' + app.Label);
    System.debug('NavType: ' + app.NavType);
    System.debug('UiType: ' + app.UiType);
    System.debug('---');
}

System.debug('\n=== Solution ===');
System.debug('Your app is configured as: Console or has no tabs visible');
System.debug('To fix:');
System.debug('1. Go to Setup → App Manager');
System.debug('2. Find "World Tour Italia Staffing"');
System.debug('3. Click Edit');
System.debug('4. In "App Options" → Change "App Navigation Style" from Console to Standard');
System.debug('5. OR add Navigation Items in the console configuration');
System.debug('6. Save and refresh');
