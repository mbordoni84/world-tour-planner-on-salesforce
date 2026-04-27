// Check Event Staffing app configuration
String appName = 'Event_Staffing';

// Query the app
List<AppDefinition> apps = [
    SELECT DurableId, Label, NavType, UiType
    FROM AppDefinition
    WHERE DeveloperName = :appName
    LIMIT 1
];

if (apps.isEmpty()) {
    System.debug('✗ App not found: ' + appName);
} else {
    AppDefinition app = apps[0];
    System.debug('=== App Found ===');
    System.debug('Label: ' + app.Label);
    System.debug('NavType: ' + app.NavType);
    System.debug('UiType: ' + app.UiType);
    System.debug('DurableId: ' + app.DurableId);

    // Query app menu items
    System.debug('\n=== App Menu Items ===');
    List<AppMenuItem> menuItems = [
        SELECT Name, Label, Type, ApplicationId
        FROM AppMenuItem
        WHERE ApplicationId = :app.DurableId
        ORDER BY Name
    ];

    if (menuItems.isEmpty()) {
        System.debug('✗ No menu items found for this app');
    } else {
        for (AppMenuItem item : menuItems) {
            System.debug('- ' + item.Label + ' (Name: ' + item.Name + ', Type: ' + item.Type + ')');
        }
    }
}

System.debug('\n=== Tab Visibility ===');
System.debug('Check if tabs are visible in Setup → Tabs:');
System.debug('1. Go to Setup → Tabs');
System.debug('2. Look for Event Sessions, Shifts, Shift Assignments');
System.debug('3. Check their visibility settings');
System.debug('\nIf tabs are in the app but not visible:');
System.debug('- Try clearing browser cache');
System.debug('- Try opening in incognito/private window');
System.debug('- Check tab visibility in user profile');
