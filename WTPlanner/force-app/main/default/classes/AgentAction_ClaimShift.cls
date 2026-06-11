public with sharing class AgentAction_ClaimShift {

    @InvocableMethod(
        label='Claim Shift'
        description='Assigns the specified shift to the currently logged-in user.'
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
                    String claimedId = ShiftMarketplaceController.claimShift(req.shiftId);
                    r.success = String.isNotBlank(claimedId);
                    r.message = r.success ? 'Shift claimed successfully.' : 'Could not claim shift.';
                }
            } catch (AuraHandledException e) {
                r.success = false;
                r.message = e.getMessage();
            } catch (Exception e) {
                r.success = false;
                r.message = 'Could not claim shift: ' + e.getMessage();
            }
            results.add(r);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(
            label='Shift ID'
            description='Salesforce ID of the shift to claim.'
            required=true
        )
        public String shiftId;
    }

    public class Result {
        @InvocableVariable(
            label='Success'
            description='True if the shift was claimed successfully.'
        )
        public Boolean success;

        @InvocableVariable(
            label='Message'
            description='Human-readable status message.'
        )
        public String message;
    }
}
