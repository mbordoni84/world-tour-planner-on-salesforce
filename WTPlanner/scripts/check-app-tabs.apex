// Check tabs in Event Staffing app
List<TabDefinition> allTabs = [
    SELECT Label, SobjectName, IsCustom
    FROM TabDefinition
    WHERE SobjectName IN ('Event_Session__c', 'Shift__c', 'Shift_Assignment__c')
    ORDER BY Label
];

System.debug('=== Tabs for Event Staffing Objects ===');
if (allTabs.isEmpty()) {
    System.debug('✗ NO TABS FOUND for Event_Session__c, Shift__c, or Shift_Assignment__c');
    System.debug('The object tabs were not created!');
} else {
    for (TabDefinition tab : allTabs) {
        System.debug('✓ Label: "' + tab.Label + '" | Object: ' + tab.SobjectName + ' | Custom: ' + tab.IsCustom);
    }
}

// Check what the user sees
System.debug('\n=== Instructions ===');
System.debug('In the Event Staffing app, you should see these tabs:');
System.debug('1. Home');
System.debug('2. Event Sessions (or similar name for Event_Session__c)');
System.debug('3. Shifts (for Shift__c)');
System.debug('4. Shift Assignments (for Shift_Assignment__c)');
System.debug('5. Shift Marketplace (LWC)');
System.debug('6. My Schedule (LWC)');
System.debug('7. Overlap Dashboard (LWC)');
System.debug('8. Master Roster (LWC)');

System.debug('\nIf you don\'t see "Event Sessions" tab:');
System.debug('- Go to Setup → App Manager → Event Staffing → Edit');
System.debug('- Check "Navigation Items" section');
System.debug('- Look for Event_Session__c in Available Items');
System.debug('- Move it to Selected Items');
