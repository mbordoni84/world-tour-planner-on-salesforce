@isTest
private class StaffingAPI_MyShiftsTest {

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
            End_Time__c = Time.newInstance(11, 0, 0, 0),
            User__c = UserInfo.getUserId()
        );
        insert shift;
    }

    @isTest
    static void testGetMyShifts() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/my-shifts';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_MyShifts.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Object> results = (List<Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testGetMyShifts_NoShifts() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = null;
        update shift;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/my-shifts';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_MyShifts.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Object> results = (List<Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(0, results.size());
    }
}
