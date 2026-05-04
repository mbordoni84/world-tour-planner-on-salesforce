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
        System.assert(result.username.contains('marco.rossi@staffingapp.'), 'Username should follow pattern');

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
    static void testCreateStaffingUser_DuplicateUsername() {
        QuickUserCreateController.createStaffingUser('Luca', 'Verdi', 'luca.verdi@test.com');

        Boolean caught = false;
        try {
            QuickUserCreateController.createStaffingUser('Luca', 'Verdi', 'luca.verdi2@test.com');
        } catch (AuraHandledException e) {
            caught = true;
        }
        System.assert(caught, 'Should throw for duplicate username');
    }
}
