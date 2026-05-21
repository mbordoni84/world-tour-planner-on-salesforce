@RestResource(urlMapping='/staffing/check-overlap')
global with sharing class StaffingAPI_CheckShiftOverlap {
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        try {
            String shiftId = RestContext.request.params.get('shiftId');
            ShiftMarketplaceController.OverlapCheckResult result =
                ShiftMarketplaceController.checkOverlap(shiftId);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(result));
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
