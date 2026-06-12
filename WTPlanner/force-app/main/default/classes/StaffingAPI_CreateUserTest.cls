@isTest
private class StaffingAPI_CreateUserTest {

    private static RestRequest buildRequest(Map<String, Object> body) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/user/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        return req;
    }

    private static Map<String, Object> parseBody() {
        return (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    static void testCreateUser_MissingFields() {
        buildRequest(new Map<String, Object>{
            'firstName' => '',
            'lastName' => 'Bianchi',
            'email' => 'anna@test.com'
        });

        Test.startTest();
        StaffingAPI_CreateUser.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> body = parseBody();
        System.assertEquals(false, body.get('success'));
        System.assert(((String) body.get('error')).contains('required'));
    }

    @isTest
    static void testCreateUser_DuplicateEmail() {
        // Create an existing active user with the email we'll try to reuse.
        QuickUserCreateController.createStaffingUser('Anna', 'Bianchi', 'anna.bianchi@test.com');

        buildRequest(new Map<String, Object>{
            'firstName' => 'Anna',
            'lastName' => 'Bianchi',
            'email' => 'anna.bianchi@test.com'
        });

        Test.startTest();
        StaffingAPI_CreateUser.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> body = parseBody();
        System.assertEquals(false, body.get('success'));
        System.assertEquals('DUPLICATE_EMAIL', body.get('error'));
        System.assertEquals('anna.bianchi@test.com', body.get('email'));
    }

    @isTest
    static void testCreateUser_Success() {
        buildRequest(new Map<String, Object>{
            'firstName' => 'Sara',
            'lastName' => 'Conti',
            'email' => 'sara.conti@test.com'
        });

        Test.startTest();
        StaffingAPI_CreateUser.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> body = parseBody();
        System.assertEquals(true, body.get('success'));
        System.assertEquals('Sara Conti', body.get('name'));
        String username = (String) body.get('username');
        System.assert(username.startsWith('sara.conti.'), 'Username should start with sara.conti.');
        System.assert(username.contains('@staffingapp.'), 'Username should contain @staffingapp.');

        Id newUserId = (Id) body.get('userId');
        User created = [SELECT Id, FirstName, LastName, Email, IsActive FROM User WHERE Id = :newUserId];
        System.assertEquals('Sara', created.FirstName);
        System.assertEquals('Conti', created.LastName);
        System.assertEquals(true, created.IsActive);

        List<PermissionSetAssignment> psa = [
            SELECT PermissionSet.Name FROM PermissionSetAssignment
            WHERE AssigneeId = :newUserId AND PermissionSet.Name = 'Staffing_App_Employee'
        ];
        System.assert(!psa.isEmpty(), 'Staffing_App_Employee permset should be assigned to the new user');
    }
}
