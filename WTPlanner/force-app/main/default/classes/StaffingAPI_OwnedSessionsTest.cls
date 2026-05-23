@isTest
private class StaffingAPI_OwnedSessionsTest {

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
            Name = 'Owned Session',
            Session_Type__c = sessionType.Id,
            Location__c = 'Main Theatre',
            Min_Shifts__c = 2,
            Max_Shifts__c = 5,
            session_owner__c = UserInfo.getUserId()
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
    static void testGetOwnedSessions() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/owned-sessions';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_OwnedSessions.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Object> results = (List<Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(1, results.size());
        Map<String, Object> session = (Map<String, Object>) results[0];
        System.assertEquals('Owned Session', session.get('name'));
    }

    @isTest
    static void testGetOwnedSessions_None() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        session.session_owner__c = null;
        update session;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/owned-sessions';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_OwnedSessions.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Object> results = (List<Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(0, results.size());
    }
}
