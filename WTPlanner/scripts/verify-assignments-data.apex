// Verify all assignments
List<Shift_Assignment__c> allAssignments = [
    SELECT Id, Name, User__c, User__r.Name, Shift__r.Name,
           Event_Session_Type__c, Assigned_User_Name__c
    FROM Shift_Assignment__c
    LIMIT 10
];

System.debug('=== Total Assignments: ' + allAssignments.size() + ' ===');

for (Shift_Assignment__c sa : allAssignments) {
    System.debug('Assignment: ' + sa.Name);
    System.debug('  User__c: ' + sa.User__c);
    System.debug('  User Name: ' + sa.User__r.Name);
    System.debug('  Assigned User Name (formula): ' + sa.Assigned_User_Name__c);
    System.debug('  Shift: ' + sa.Shift__r.Name);
    System.debug('  Session Type: ' + sa.Event_Session_Type__c);
    System.debug('---');
}

System.debug('\n✓ All fields are now accessible!');
System.debug('Go to Shift Assignments tab and click on a record to see all fields.');
