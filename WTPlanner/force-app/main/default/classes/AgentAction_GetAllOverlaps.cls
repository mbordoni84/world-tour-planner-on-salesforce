public with sharing class AgentAction_GetAllOverlaps {

    public class Request {
        @InvocableVariable(label='User Filter' description='Optional: filter by user name to see only their overlaps' required=false)
        public String userFilter;
    }

    public class Result {
        @InvocableVariable(label='Overlaps Summary' description='Summary of all overlapping shifts in the org')
        public String summary;
        @InvocableVariable(label='Overlap Count' description='Total number of users with overlaps')
        public Integer overlapCount;
    }

    @InvocableMethod(label='Get All Overlaps' description='Returns all scheduling overlaps across the org, grouped by user. Admin view.' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String userFilter = requests[0].userFilter;

        String query = 'SELECT Id, Start_Time__c, End_Time__c, User__c, User__r.Name, ' +
            'Session__r.Name, Session__r.Location__c ' +
            'FROM Shift__c WHERE Has_Overlap__c = true AND User__c != null';

        if (String.isNotBlank(userFilter)) {
            query += ' AND User__r.Name LIKE \'%' + String.escapeSingleQuotes(userFilter) + '%\'';
        }

        query += ' ORDER BY User__r.Name, Start_Time__c';

        List<Shift__c> overlappingShifts = Database.query(query, AccessLevel.USER_MODE);

        Map<String, List<String>> shiftsByUser = new Map<String, List<String>>();

        for (Shift__c sh : overlappingShifts) {
            String userName = sh.User__r.Name;
            String timeRange = StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                               StaffingAgentActions.formatTime(sh.End_Time__c);
            String line = '  - ' + sh.Session__r.Name + ' at ' + sh.Session__r.Location__c + ', ' + timeRange + ' [Shift ID: ' + sh.Id + ']';

            if (!shiftsByUser.containsKey(userName)) {
                shiftsByUser.put(userName, new List<String>());
            }
            shiftsByUser.get(userName).add(line);
        }

        List<String> lines = new List<String>();
        for (String userName : shiftsByUser.keySet()) {
            lines.add(userName + ' (' + shiftsByUser.get(userName).size() + ' overlapping shifts):');
            lines.addAll(shiftsByUser.get(userName));
        }

        Result result = new Result();
        result.overlapCount = shiftsByUser.size();
        result.summary = shiftsByUser.isEmpty() ? 'No scheduling overlaps found in the org.' :
            'Found overlaps for ' + shiftsByUser.size() + ' user(s):\n' + String.join(lines, '\n');

        return new List<Result>{ result };
    }
}
