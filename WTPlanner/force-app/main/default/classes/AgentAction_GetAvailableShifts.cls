public with sharing class AgentAction_GetAvailableShifts {

    @InvocableMethod(
        label='Get Available Shifts'
        description='Returns sessions that have at least one unclaimed shift and are not frozen.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Integer count = requests == null ? 1 : Math.max(requests.size(), 1);
        for (Integer i = 0; i < count; i++) {
            Result r = new Result();
            r.sessions = new List<SessionInfo>();
            try {
                for (ShiftMarketplaceController.SessionWrapper sw : ShiftMarketplaceController.getSessionsNeedingStaff()) {
                    if (sw.isFrozen == true) continue;
                    if (sw.availableShifts == null || sw.availableShifts <= 0) continue;

                    String firstShiftId = null;
                    String firstShiftRange = null;
                    if (sw.shifts != null) {
                        for (ShiftMarketplaceController.ShiftDetail sd : sw.shifts) {
                            if (sd.isClaimed == false) {
                                firstShiftId = sd.id;
                                firstShiftRange = sd.startTime + ' - ' + sd.endTime;
                                break;
                            }
                        }
                    }

                    SessionInfo si = new SessionInfo();
                    si.sessionId = sw.id;
                    si.sessionName = sw.name;
                    si.sessionType = sw.sessionType;
                    si.location = sw.location;
                    si.availableShiftCount = sw.availableShifts;
                    si.firstAvailableShiftId = firstShiftId;
                    si.firstAvailableTimeRange = firstShiftRange;
                    r.sessions.add(si);
                }
                r.count = r.sessions.size();
            } catch (Exception e) {
                r.sessions = new List<SessionInfo>();
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
            label='Sessions'
            description='Sessions with at least one unclaimed shift.'
        )
        public List<SessionInfo> sessions;

        @InvocableVariable(
            label='Count'
            description='Number of sessions with available shifts.'
        )
        public Integer count;
    }

    public class SessionInfo {
        @InvocableVariable(label='Session ID' description='Salesforce ID of the Session__c record')
        public String sessionId;
        @InvocableVariable(label='Session Name' description='Display name of the session')
        public String sessionName;
        @InvocableVariable(label='Session Type' description='Name of the parent Session_Type__c')
        public String sessionType;
        @InvocableVariable(label='Location' description='Where the session takes place')
        public String location;
        @InvocableVariable(label='Available Shift Count' description='Number of unclaimed shifts on this session')
        public Integer availableShiftCount;
        @InvocableVariable(label='First Available Shift ID' description='ID of the first unclaimed shift, used by claim_shift')
        public String firstAvailableShiftId;
        @InvocableVariable(label='First Available Time Range' description='Time range (HH:mm - HH:mm) of the first unclaimed shift')
        public String firstAvailableTimeRange;
    }
}
