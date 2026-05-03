@isTest
private class StaffingAPI_DigestTest {
    @TestSetup
    static void setup() {
        TestDataFactory.generateFullDataset();
    }

    @isTest
    static void testDigestEndpoint() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/staffing/digest';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        StaffingAPI_Digest.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(body);

        System.assert(result.containsKey('summary'));
        System.assert(result.containsKey('bySessionType'));
        System.assert(result.containsKey('sessionsNeedingStaff'));
        System.assert(result.containsKey('leaderboard'));
        System.assert(result.containsKey('overlaps'));
        System.assert(result.containsKey('userDigests'));

        Map<String, Object> summary = (Map<String, Object>)result.get('summary');
        System.assert((Integer)summary.get('totalShifts') > 0);
        System.assert((Integer)summary.get('assigned') > 0);
    }
}
