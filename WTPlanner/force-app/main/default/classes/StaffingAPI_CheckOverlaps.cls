@RestResource(urlMapping='/staffing/overlaps')
global with sharing class StaffingAPI_CheckOverlaps {
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        try {
            List<OverlapDashboardController.OverlapWrapper> overlaps =
                OverlapDashboardController.getOverlappingShifts();
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(overlaps));
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
