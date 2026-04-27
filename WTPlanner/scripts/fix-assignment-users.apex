// Fix existing assignments by assigning users to them
List<Shift_Assignment__c> assignments = [
    SELECT Id, Name, User__c, Shift__c
    FROM Shift_Assignment__c
    WHERE User__c = null
];

System.debug('=== Fixing ' + assignments.size() + ' assignments without User ===');

// Get available users
List<User> users = [
    SELECT Id, Name
    FROM User
    WHERE IsActive = true
    LIMIT 20
];

if (users.isEmpty()) {
    System.debug('✗ No users found!');
} else {
    System.debug('Found ' + users.size() + ' active users');

    // Assign users randomly
    Integer userIndex = 0;
    for (Shift_Assignment__c sa : assignments) {
        sa.User__c = users[Math.mod(userIndex, users.size())].Id;
        userIndex++;
    }

    update assignments;
    System.debug('✓ Updated ' + assignments.size() + ' assignments with User__c');
    System.debug('Refresh the Shift Assignments page to see the changes!');
}
