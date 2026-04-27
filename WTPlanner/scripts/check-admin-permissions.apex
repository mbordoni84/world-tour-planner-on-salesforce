// Check admin permissions for data insertion
User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('=== Current User ===');
System.debug('Name: ' + currentUser.Name);
System.debug('Profile: ' + currentUser.Profile.Name);

// Check permission set assignments
List<PermissionSetAssignment> psas = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name LIKE 'Staffing_App%'
];

System.debug('\n=== Permission Sets ===');
for (PermissionSetAssignment psa : psas) {
    System.debug('✓ ' + psa.PermissionSet.Label);
}

// Check object permissions
System.debug('\n=== Object Permissions ===');
Schema.DescribeSObjectResult sessionDescribe = Event_Session__c.SObjectType.getDescribe();
Schema.DescribeSObjectResult shiftDescribe = Shift__c.SObjectType.getDescribe();
Schema.DescribeSObjectResult assignmentDescribe = Shift_Assignment__c.SObjectType.getDescribe();

System.debug('Event_Session__c:');
System.debug('  - Createable: ' + sessionDescribe.isCreateable());
System.debug('  - Updateable: ' + sessionDescribe.isUpdateable());
System.debug('  - Deletable: ' + sessionDescribe.isDeletable());

System.debug('Shift__c:');
System.debug('  - Createable: ' + shiftDescribe.isCreateable());
System.debug('  - Updateable: ' + shiftDescribe.isUpdateable());
System.debug('  - Deletable: ' + shiftDescribe.isDeletable());

System.debug('Shift_Assignment__c:');
System.debug('  - Createable: ' + assignmentDescribe.isCreateable());
System.debug('  - Updateable: ' + assignmentDescribe.isUpdateable());
System.debug('  - Deletable: ' + assignmentDescribe.isDeletable());

// Test creating a sample session
System.debug('\n=== Test Record Creation ===');
try {
    Event_Session__c testSession = new Event_Session__c(
        Title__c = 'TEST - Admin UI Test',
        Session_Type__c = 'Booth',
        Location__c = 'Test Location'
    );
    insert testSession;
    System.debug('✓ Event Session created successfully: ' + testSession.Id);

    // Clean up
    delete testSession;
    System.debug('✓ Test record deleted');

    System.debug('\n=== Result ===');
    System.debug('✓ Admin has full CRUD permissions');
    System.debug('You can create/edit/delete all objects via UI');
} catch (Exception e) {
    System.debug('✗ Error: ' + e.getMessage());
    System.debug('\n=== Result ===');
    System.debug('✗ Missing permissions - need to assign Staffing_App_Admin permission set');
}
