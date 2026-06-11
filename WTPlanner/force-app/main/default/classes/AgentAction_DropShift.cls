public with sharing class AgentAction_DropShift {

    @InvocableMethod(
        label='Drop Shift'
        description='Removes the current user assignment from the specified shift.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null) return results;

        for (Request req : requests) {
            Result r = new Result();
            try {
                if (String.isBlank(req.shiftId)) {
                    r.success = false;
                    r.message = 'Missing shift ID.';
                } else {
                    ShiftMarketplaceController.dropShift(req.shiftId);
                    r.success = true;
                    r.message = 'Shift dropped.';
                }
            } catch (AuraHandledException e) {
                r.success = false;
                r.message = e.getMessage();
            } catch (Exception e) {
                r.success = false;
                r.message = 'Could not drop shift: ' + e.getMessage();
            }
            results.add(r);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(
            label='Shift ID'
            description='Salesforce ID of the shift to drop.'
            required=true
        )
        public String shiftId;
    }

    public class Result {
        @InvocableVariable(
            label='Success'
            description='True if the shift was dropped successfully.'
        )
        public Boolean success;

        @InvocableVariable(
            label='Message'
            description='Human-readable status message.'
        )
        public String message;
    }
}
