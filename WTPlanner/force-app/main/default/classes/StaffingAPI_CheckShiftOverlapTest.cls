@isTest
private class StaffingAPI_CheckShiftOverlapTest {

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

        List<Shift__c> shifts = new List<Shift__c>{
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(11, 0, 0, 0),
                User__c = UserInfo.getUserId()
            ),
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(10, 0, 0, 0),
                End_Time__c = Time.newInstance(12, 0, 0, 0)
            )
        };
        insert shifts;
    }

    @isTest
    static void testCheckOverlap_HasOverlap() {
        Shift__c unclaimed = [
            SELECT Id FROM Shift__c
            WHERE User__c = null LIMIT 1
        ];

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/check-overlap';
        req.httpMethod = 'GET';
        req.params.put('shiftId', unclaimed.Id);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_CheckShiftOverlap.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(true, result.get('hasOverlap'));
    }

    @isTest
    static void testCheckOverlap_NoOverlap() {
        Shift__c unclaimed = [
            SELECT Id FROM Shift__c
            WHERE User__c = null LIMIT 1
        ];
        Shift__c claimed = [
            SELECT Id FROM Shift__c
            WHERE User__c != null LIMIT 1
        ];
        claimed.User__c = null;
        update claimed;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/check-overlap';
        req.httpMethod = 'GET';
        req.params.put('shiftId', unclaimed.Id);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_CheckShiftOverlap.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(false, result.get('hasOverlap'));
    }
}
