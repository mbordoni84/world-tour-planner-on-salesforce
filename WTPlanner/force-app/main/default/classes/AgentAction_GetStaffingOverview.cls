public with sharing class AgentAction_GetStaffingOverview {

    public class Request {
        @InvocableVariable(label='Placeholder' description='No input needed' required=false)
        public String placeholder;
    }

    public class Result {
        @InvocableVariable(label='Overview Summary' description='Staffing overview with stats')
        public String summary;
        @InvocableVariable(label='Total Sessions' description='Total number of sessions')
        public Integer totalSessions;
        @InvocableVariable(label='Sessions Needing Staff' description='Sessions below minimum staffing')
        public Integer sessionsNeedingStaff;
    }

    @InvocableMethod(label='Get Staffing Overview' description='Returns global staffing stats including sessions needing staff, fully staffed sessions, and top contributors' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        List<Session__c> sessions = [
            SELECT Name, Min_Shifts__c, Max_Shifts__c, Location__c,
                   Session_Type__r.Name, Is_Frozen__c,
                   (SELECT Id, User__c, User__r.Name FROM Shifts__r)
            FROM Session__c
            WHERE Is_Frozen__c = false
            ORDER BY Name
        ];

        Integer totalSessions = sessions.size();
        Integer needsStaff = 0;
        Integer fullyStaffed = 0;
        List<String> urgentSessions = new List<String>();
        Map<String, Integer> userShiftCount = new Map<String, Integer>();

        for (Session__c sess : sessions) {
            Integer minRequired = sess.Min_Shifts__c != null ? (Integer)sess.Min_Shifts__c : 1;
            Integer claimed = 0;

            for (Shift__c sh : sess.Shifts__r) {
                if (sh.User__c != null) {
                    claimed++;
                    String userName = sh.User__r.Name;
                    userShiftCount.put(userName, (userShiftCount.containsKey(userName) ? userShiftCount.get(userName) : 0) + 1);
                }
            }

            if (claimed < minRequired) {
                needsStaff++;
                urgentSessions.add('- ' + sess.Name + ' (' + sess.Session_Type__r.Name + '): ' + claimed + '/' + minRequired + ' min staffed');
            } else if (claimed == sess.Shifts__r.size() && sess.Shifts__r.size() > 0) {
                fullyStaffed++;
            }
        }

        // Top 5 contributors
        List<String> topContributors = new List<String>();
        List<String> allUsers = new List<String>(userShiftCount.keySet());
        // Simple sort by count (descending)
        for (Integer i = 0; i < Math.min(5, allUsers.size()); i++) {
            String topUser = null;
            Integer topCount = 0;
            for (String u : allUsers) {
                if (userShiftCount.get(u) > topCount && !topContributors.contains(u + ': ' + userShiftCount.get(u) + ' shifts')) {
                    topUser = u;
                    topCount = userShiftCount.get(u);
                }
            }
            if (topUser != null) {
                topContributors.add(topUser + ': ' + topCount + ' shifts');
            }
        }

        String summary = 'Staffing Overview:\n' +
            '- Total active sessions: ' + totalSessions + '\n' +
            '- Sessions needing staff: ' + needsStaff + '\n' +
            '- Sessions fully staffed: ' + fullyStaffed + '\n';

        if (!urgentSessions.isEmpty()) {
            summary += '\nSessions needing staff:\n' + String.join(urgentSessions, '\n');
        }

        if (!topContributors.isEmpty()) {
            summary += '\n\nTop contributors:\n- ' + String.join(topContributors, '\n- ');
        }

        Result result = new Result();
        result.summary = summary;
        result.totalSessions = totalSessions;
        result.sessionsNeedingStaff = needsStaff;
        return new List<Result>{ result };
    }
}
