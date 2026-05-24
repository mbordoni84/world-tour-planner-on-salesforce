public with sharing class AgentAction_GetMyShifts {

    public class Request {
        @InvocableVariable(label='Placeholder' description='No input needed' required=false)
        public String placeholder;
    }

    public class Result {
        @InvocableVariable(label='Shifts Summary' description='Summary of user shifts')
        public String summary;
        @InvocableVariable(label='Shift Count' description='Number of shifts assigned')
        public Integer shiftCount;
        @InvocableVariable(label='Has Overlaps' description='Whether the user has overlapping shifts')
        public Boolean hasOverlaps;
    }

    @InvocableMethod(label='Get My Shifts' description='Returns all shifts assigned to the current user with session details and overlap warnings' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        List<Shift__c> shifts = [
            SELECT Name, Start_Time__c, End_Time__c, Has_Overlap__c,
                   Session__r.Id, Session__r.Name, Session__r.Location__c,
                   Session__r.Session_Type__r.Name,
                   Session__r.session_owner__r.Name
            FROM Shift__c
            WHERE User__c = :UserInfo.getUserId()
            ORDER BY Start_Time__c
        ];

        List<String> lines = new List<String>();
        Boolean hasOverlaps = false;

        for (Shift__c sh : shifts) {
            String timeRange = StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                               StaffingAgentActions.formatTime(sh.End_Time__c);
            String overlap = sh.Has_Overlap__c ? ' !! OVERLAP' : '';
            if (sh.Has_Overlap__c) hasOverlaps = true;

            String ownerName = sh.Session__r.session_owner__r != null ? sh.Session__r.session_owner__r.Name : 'N/A';
            lines.add('- ' + sh.Session__r.Name + ' (' + sh.Session__r.Session_Type__r.Name + ') [Session ID: ' + sh.Session__r.Id + '] at ' +
                       sh.Session__r.Location__c + ', ' + timeRange + ' | Owner: ' + ownerName + ' [Shift ID: ' + sh.Id + ']' + overlap);
        }

        Result result = new Result();
        result.shiftCount = shifts.size();
        result.hasOverlaps = hasOverlaps;
        result.summary = shifts.isEmpty() ? 'You have no shifts assigned.' :
                         'You have ' + shifts.size() + ' shift(s):\n' + String.join(lines, '\n') +
                         (hasOverlaps ? '\n\nWarning: you have overlapping shifts!' : '');

        return new List<Result>{ result };
    }
}
