// Run with: sf apex run --file scripts/apex/seed-agent-test-users.apex --target-org <alias>
//
// Companion to seed-agent-test-data.apex. Creates 2 staff test users with
// the Staffing_App_Employee permset, in a separate transaction so the
// non-setup DML in seed-agent-test-data.apex doesn't trip mixed-DML.
//
// Idempotent: skips creation if usernames already exist.

List<User> existing = [
    SELECT Id FROM User WHERE Username LIKE 'agenttest%@worldtour.test'
];
if (existing.size() >= 2) {
    System.debug('Test staff users already exist, skipping.');
    return;
}

Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
Long ts = System.currentTimeMillis();
List<User> staff = new List<User>{
    new User(
        FirstName = 'Agent', LastName = 'Test1',
        Email = 'agenttest1@worldtour.test',
        Username = 'agenttest1+' + ts + '@worldtour.test',
        Alias = 'atest1', TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US', ProfileId = standardProfile.Id, IsActive = true
    ),
    new User(
        FirstName = 'Agent', LastName = 'Test2',
        Email = 'agenttest2@worldtour.test',
        Username = 'agenttest2+' + ts + '@worldtour.test',
        Alias = 'atest2', TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US', ProfileId = standardProfile.Id, IsActive = true
    )
};
insert staff;

PermissionSet employeePs = [SELECT Id FROM PermissionSet WHERE Name = 'Staffing_App_Employee' LIMIT 1];
List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
for (User u : staff) {
    psas.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = employeePs.Id));
}
insert psas;

System.debug('Created 2 staff test users with Staffing_App_Employee permset.');
