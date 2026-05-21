@RestResource(urlMapping='/staffing/drop')
global with sharing class StaffingAPI_DropShift {
    @HttpPost
    global static void doPost() {
        RestResponse res = RestContext.response;
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.request.requestBody.toString()
            );
            String shiftId = (String) body.get('shiftId');
            ShiftMarketplaceController.dropShift(shiftId);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{ 'success' => true }
            ));
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
