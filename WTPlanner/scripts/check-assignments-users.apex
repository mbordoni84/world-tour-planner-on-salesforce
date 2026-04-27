// Check if Shift Assignments have User populated
List<Shift_Assignment__c> assignments = [
    SELECT Id, Name, User__c, User__r.Name, Shift__c, Shift__r.Name
    FROM Shift_Assignment__c
    LIMIT 10
];

System.debug('=== Shift Assignments ===');
Integer withUser = 0;
Integer withoutUser = 0;

for (Shift_Assignment__c sa : assignments) {
    if (sa.User__c != null) {
        System.debug('✓ ' + sa.Name + ' | User: ' + sa.User__r.Name + ' | Shift: ' + sa.Shift__r.Name);
        withUser++;
    } else {
        System.debug('✗ ' + sa.Name + ' | User: NULL | Shift: ' + sa.Shift__r.Name);
        withoutUser++;
    }
}

System.debug('\n=== Summary ===');
System.debug('Assignments WITH User: ' + withUser);
System.debug('Assignments WITHOUT User: ' + withoutUser);

if (withoutUser > 0) {
    System.debug('\n=== Problem ===');
    System.debug('Some assignments don\'t have User populated!');
    System.debug('The test data might not have set the User field correctly.');
}
