public with sharing class AgentAction_CheckOverlaps {

    public class Request {
        @InvocableVariable(label='Placeholder' description='No input needed' required=false)
        public String placeholder;
    }

    public class Result {
        @InvocableVariable(label='Overlaps Summary' description='Details of overlapping shifts')
        public String summary;
        @InvocableVariable(label='Has Overlaps' description='Whether overlaps were found')
        public Boolean hasOverlaps;
        @InvocableVariable(label='Overlap Count' description='Number of overlapping shift pairs')
        public Integer overlapCount;
    }

    @InvocableMethod(label='Check My Overlaps' description='Checks if the current user has any overlapping shift assignments' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        List<Shift__c> shifts = [
            SELECT Name, Start_Time__c, End_Time__c, Has_Overlap__c,
                   Session__r.Name, Session__r.Location__c
            FROM Shift__c
            WHERE User__c = :UserInfo.getUserId()
              AND Has_Overlap__c = true
            ORDER BY Start_Time__c
        ];

        Result result = new Result();

        if (shifts.isEmpty()) {
            result.hasOverlaps = false;
            result.overlapCount = 0;
            result.summary = 'No overlapping shifts found. Your schedule is clear!';
            return new List<Result>{ result };
        }

        List<String> lines = new List<String>();
        for (Shift__c sh : shifts) {
            lines.add('- ' + sh.Session__r.Name + ' at ' + sh.Session__r.Location__c +
                       ' (' + StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                       StaffingAgentActions.formatTime(sh.End_Time__c) + ')');
        }

        result.hasOverlaps = true;
        result.overlapCount = shifts.size();
        result.summary = 'Found ' + shifts.size() + ' shift(s) with overlaps:\n' +
                         String.join(lines, '\n') +
                         '\n\nConsider dropping one of the conflicting shifts.';

        return new List<Result>{ result };
    }
}
