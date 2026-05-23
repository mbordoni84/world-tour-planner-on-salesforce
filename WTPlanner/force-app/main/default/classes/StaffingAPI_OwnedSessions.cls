@RestResource(urlMapping='/staffing/owned-sessions')
global with sharing class StaffingAPI_OwnedSessions {
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        try {
            List<ShiftMarketplaceController.SessionWrapper> sessions =
                ShiftMarketplaceController.getOwnedSessions();
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(sessions));
        } catch (AuraHandledException e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() }
            ));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() }
            ));
        }
    }
}
