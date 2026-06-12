@IsTest
private class QuickUserCreateControllerTest {

    @IsTest
    static void testCreateStaffingUser_Success() {
        Test.startTest();
        QuickUserCreateController.UserResult result =
            QuickUserCreateController.createStaffingUser('Marco', 'Rossi', 'marco.rossi@test.com');
        Test.stopTest();

        System.assertNotEquals(null, result.userId, 'User should be created');
        System.assertEquals('Marco Rossi', result.name);
        // The controller appends a timestamp between the name and the suffix to
        // keep usernames unique, so the prefix does not include "@" — match the
        // two parts separately.
        System.assert(result.username.startsWith('marco.rossi.'), 'Username should start with marco.rossi.');
        System.assert(result.username.contains('@staffingapp.'), 'Username should contain @staffingapp.');

        User created = [SELECT Id, FirstName, LastName, Email, IsActive FROM User WHERE Id = :result.userId];
        System.assertEquals('Marco', created.FirstName);
        System.assertEquals('Rossi', created.LastName);
        System.assertEquals('marco.rossi@test.com', created.Email);
        System.assertEquals(true, created.IsActive);

        List<PermissionSetAssignment> psas = [
            SELECT PermissionSet.Name FROM PermissionSetAssignment
            WHERE AssigneeId = :result.userId
              AND PermissionSet.Name LIKE 'Staffing_App_%'
        ];
        Set<String> permSetNames = new Set<String>();
        for (PermissionSetAssignment psa : psas) {
            permSetNames.add(psa.PermissionSet.Name);
        }
        System.assert(permSetNames.contains('Staffing_App_Employee'), 'Employee perm set should be assigned');
    }

    @IsTest
    static void testCreateStaffingUser_MissingFields() {
        Boolean caught = false;
        try {
            QuickUserCreateController.createStaffingUser('', 'Rossi', 'test@test.com');
        } catch (AuraHandledException e) {
            caught = true;
            System.assert(e.getMessage().contains('required'), 'Should mention required fields');
        }
        System.assert(caught, 'Should throw for missing first name');
    }

    @IsTest
    static void testCreateStaffingUser_DuplicateEmail() {
        // The controller refuses to create a user when another active user
        // already has the same email. Duplicate username is hard to force
        // because the controller stamps a timestamp into every generated
        // username, so we exercise the email-collision path instead.
        QuickUserCreateController.createStaffingUser('Luca', 'Verdi', 'luca.verdi@test.com');

        Boolean caught = false;
        try {
            QuickUserCreateController.createStaffingUser('Luca', 'Verdi', 'luca.verdi@test.com');
        } catch (AuraHandledException e) {
            caught = true;
            System.assert(
                e.getMessage().contains('already exists'),
                'Should mention the existing user'
            );
        }
        System.assert(caught, 'Should throw when email is already in use');
    }
}
