// Check which tabs are available in the app
List<TabDefinition> tabs = [
    SELECT Label, SobjectName, IsCustom
    FROM TabDefinition
    WHERE SobjectName IN ('Event_Session__c', 'Shift__c', 'Shift_Assignment__c', 'Home')
    ORDER BY Label
];

System.debug('=== Available Object Tabs ===');
for (TabDefinition tab : tabs) {
    System.debug('Label: ' + tab.Label + ' | Object: ' + tab.SobjectName + ' | Custom: ' + tab.IsCustom);
}

// Check app configuration
String appId = '02uHo000002C5YWIA0'; // World Tour Staffing app ID
System.debug('\n=== App Configuration ===');
System.debug('Navigate to Setup → App Manager → World Tour Italia Staffing → Edit');
System.debug('Add these tabs to Navigation Items:');
System.debug('1. Home');
System.debug('2. Event Sessions');
System.debug('3. Shifts');
System.debug('4. Shift Assignments');
