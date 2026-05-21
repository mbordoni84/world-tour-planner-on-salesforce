@isTest
private class StaffingAPI_AvailableSessionsTest {

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
    static void testGetAvailableSessions() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/available-sessions';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_AvailableSessions.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Object> results = (List<Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(1, results.size());
    }
}
