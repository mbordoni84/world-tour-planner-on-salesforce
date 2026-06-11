public with sharing class AgentAction_GetMyOverlaps {

    @InvocableMethod(
        label='Get My Overlaps'
        description='Returns shift pairs that overlap in time for the currently logged-in user.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Integer count = requests == null ? 1 : Math.max(requests.size(), 1);
        for (Integer i = 0; i < count; i++) {
            Result r = new Result();
            r.overlaps = new List<OverlapInfo>();
            try {
                for (OverlapDashboardController.OverlapWrapper ow : OverlapDashboardController.getOverlappingShifts()) {
                    OverlapInfo o = new OverlapInfo();
                    o.shift1Id = ow.shift1Id;
                    o.shift1Session = ow.shift1Session;
                    o.shift1Time = ow.shift1Time;
                    o.shift2Id = ow.shift2Id;
                    o.shift2Session = ow.shift2Session;
                    o.shift2Time = ow.shift2Time;
                    r.overlaps.add(o);
                }
                r.count = r.overlaps.size();
            } catch (Exception e) {
                r.overlaps = new List<OverlapInfo>();
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
            label='Overlaps'
            description='Pairs of shifts that overlap in time for the current user.'
        )
        public List<OverlapInfo> overlaps;

        @InvocableVariable(
            label='Count'
            description='Number of overlap pairs returned.'
        )
        public Integer count;
    }

    public class OverlapInfo {
        @InvocableVariable(label='Shift 1 ID' description='Salesforce ID of the first conflicting shift')
        public String shift1Id;
        @InvocableVariable(label='Shift 1 Session' description='Session name of the first conflicting shift')
        public String shift1Session;
        @InvocableVariable(label='Shift 1 Time' description='Time range of the first conflicting shift')
        public String shift1Time;
        @InvocableVariable(label='Shift 2 ID' description='Salesforce ID of the second conflicting shift')
        public String shift2Id;
        @InvocableVariable(label='Shift 2 Session' description='Session name of the second conflicting shift')
        public String shift2Session;
        @InvocableVariable(label='Shift 2 Time' description='Time range of the second conflicting shift')
        public String shift2Time;
    }
}
