@RestResource(urlMapping='/staffing/my-shifts')
global with sharing class StaffingAPI_MyShifts {
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        try {
            List<ShiftMarketplaceController.ShiftWrapper> shifts =
                ShiftMarketplaceController.getMyShifts();
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(shifts));
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
