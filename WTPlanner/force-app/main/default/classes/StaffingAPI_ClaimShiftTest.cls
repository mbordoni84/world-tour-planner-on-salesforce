@isTest
private class StaffingAPI_ClaimShiftTest {

    @testSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c sessionType = new Session_Type__c(
            Name = 'Theatre',
            Event__c = event.Id
        );
        insert sessionType;

        Session__c session = new Session__c(
            Name = 'Test Session',
            Session_Type__c = sessionType.Id,
            Location__c = 'Main Theatre',
            Min_Shifts__c = 2,
            Max_Shifts__c = 5
        );
        insert session;

        Shift__c shift = new Shift__c(
            Session__c = session.Id,
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert shift;
    }

    @isTest
    static void testClaimShift_Success() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/claim';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"shiftId":"' + shift.Id + '"}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_ClaimShift.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(true, result.get('success'));

        Shift__c updated = [SELECT User__c FROM Shift__c WHERE Id = :shift.Id];
        System.assertEquals(UserInfo.getUserId(), updated.User__c);
    }

    @isTest
    static void testClaimShift_AlreadyClaimed() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/claim';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"shiftId":"' + shift.Id + '"}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_ClaimShift.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(false, result.get('success'));
    }
}
