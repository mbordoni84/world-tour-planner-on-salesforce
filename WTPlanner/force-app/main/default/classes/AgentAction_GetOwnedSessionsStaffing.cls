public with sharing class AgentAction_GetOwnedSessionsStaffing {

    @InvocableMethod(
        label='Get Owned Sessions Staffing'
        description='Returns staffing summary for sessions where the current user is the session owner.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Integer count = requests == null ? 1 : Math.max(requests.size(), 1);
        for (Integer i = 0; i < count; i++) {
            Result r = new Result();
            r.ownedSessions = new List<SessionStaffingInfo>();
            try {
                for (ShiftMarketplaceController.SessionWrapper sw : ShiftMarketplaceController.getOwnedSessions()) {
                    SessionStaffingInfo si = new SessionStaffingInfo();
                    si.sessionId = sw.id;
                    si.sessionName = sw.name;
                    si.sessionType = sw.sessionType;
                    si.totalShifts = sw.totalShifts;
                    si.claimedShifts = sw.claimedShifts;
                    si.availableShifts = sw.availableShifts;
                    si.staffingStatus = simplifyStatus(sw);
                    r.ownedSessions.add(si);
                }
                r.count = r.ownedSessions.size();
            } catch (Exception e) {
                r.ownedSessions = new List<SessionStaffingInfo>();
                r.count = 0;
            }
            results.add(r);
        }
        return results;
    }

    private static String simplifyStatus(ShiftMarketplaceController.SessionWrapper sw) {
        if (sw.needsStaff == true) return 'Needs Staff';
        if (sw.isFull == true) return 'Fully Staffed';
        return 'Min Reached';
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
            label='Owned Sessions'
            description='Sessions where the current user is the session owner, with staffing summary.'
        )
        public List<SessionStaffingInfo> ownedSessions;

        @InvocableVariable(
            label='Count'
            description='Number of owned sessions returned.'
        )
        public Integer count;
    }

    public class SessionStaffingInfo {
        @InvocableVariable(label='Session ID' description='Salesforce ID of the Session__c record')
        public String sessionId;
        @InvocableVariable(label='Session Name' description='Display name of the session')
        public String sessionName;
        @InvocableVariable(label='Session Type' description='Name of the parent Session_Type__c')
        public String sessionType;
        @InvocableVariable(label='Total Shifts' description='Total shifts attached to the session')
        public Integer totalShifts;
        @InvocableVariable(label='Claimed Shifts' description='Number of shifts already assigned to a user')
        public Integer claimedShifts;
        @InvocableVariable(label='Available Shifts' description='Number of unclaimed shifts on the session')
        public Integer availableShifts;
        @InvocableVariable(label='Staffing Status' description='Needs Staff, Min Reached, or Fully Staffed')
        public String staffingStatus;
    }
}
