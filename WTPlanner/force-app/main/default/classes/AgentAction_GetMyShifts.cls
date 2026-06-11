public with sharing class AgentAction_GetMyShifts {

    @InvocableMethod(
        label='Get My Shifts'
        description='Returns the list of shifts assigned to the currently logged-in user.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Integer count = requests == null ? 1 : Math.max(requests.size(), 1);
        for (Integer i = 0; i < count; i++) {
            Result r = new Result();
            r.shifts = new List<ShiftInfo>();
            try {
                for (ShiftMarketplaceController.ShiftWrapper w : ShiftMarketplaceController.getMyShifts()) {
                    ShiftInfo s = new ShiftInfo();
                    s.shiftId = w.id;
                    s.sessionName = w.sessionName;
                    s.sessionType = w.sessionType;
                    s.location = w.sessionLocation;
                    s.startTime = w.startTime;
                    s.endTime = w.endTime;
                    s.hasOverlap = w.hasOverlap == true;
                    r.shifts.add(s);
                }
                r.count = r.shifts.size();
            } catch (Exception e) {
                r.shifts = new List<ShiftInfo>();
                r.count = 0;
            }
            results.add(r);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(
            label='Filler'
            description='Unused placeholder; required because the action takes no real input.'
            required=false
        )
        public String filler;
    }

    public class Result {
        @InvocableVariable(
            label='Shifts'
            description='List of shifts assigned to the current user.'
        )
        public List<ShiftInfo> shifts;

        @InvocableVariable(
            label='Count'
            description='Number of shifts returned.'
        )
        public Integer count;
    }

    public class ShiftInfo {
        @InvocableVariable(label='Shift ID' description='Salesforce ID of the shift record')
        public String shiftId;
        @InvocableVariable(label='Session Name' description='Name of the parent session')
        public String sessionName;
        @InvocableVariable(label='Session Type' description='Session type label')
        public String sessionType;
        @InvocableVariable(label='Location' description='Where the session takes place')
        public String location;
        @InvocableVariable(label='Start Time' description='Shift start time as HH:mm')
        public String startTime;
        @InvocableVariable(label='End Time' description='Shift end time as HH:mm')
        public String endTime;
        @InvocableVariable(label='Has Overlap' description='True when the shift conflicts with another shift assigned to the same user')
        public Boolean hasOverlap;
    }
}
