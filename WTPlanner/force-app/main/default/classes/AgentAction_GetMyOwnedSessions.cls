public with sharing class AgentAction_GetMyOwnedSessions {

    public class Request {
        @InvocableVariable(label='Placeholder' description='No input needed' required=false)
        public String placeholder;
    }

    public class Result {
        @InvocableVariable(label='Owned Sessions Summary' description='Detailed staffing for sessions the user owns')
        public String summary;
        @InvocableVariable(label='Session Count' description='Number of sessions owned')
        public Integer sessionCount;
    }

    @InvocableMethod(label='Get My Owned Sessions' description='Returns sessions owned by the current user with full staffing details including who is assigned to each shift' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        List<Session__c> sessions = [
            SELECT Name, Location__c, Min_Shifts__c, Max_Shifts__c,
                   Session_Type__r.Name, Is_Frozen__c,
                   (SELECT Id, Start_Time__c, End_Time__c, User__c, User__r.Name, Has_Overlap__c
                    FROM Shifts__r ORDER BY Start_Time__c)
            FROM Session__c
            WHERE session_owner__c = :UserInfo.getUserId()
            ORDER BY Name
        ];

        List<String> sessionBlocks = new List<String>();

        for (Session__c sess : sessions) {
            Integer minRequired = sess.Min_Shifts__c != null ? (Integer)sess.Min_Shifts__c : 1;
            Integer claimed = 0;
            List<String> shiftLines = new List<String>();

            for (Shift__c sh : sess.Shifts__r) {
                String timeRange = StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                                   StaffingAgentActions.formatTime(sh.End_Time__c);
                if (sh.User__c != null) {
                    claimed++;
                    String overlap = sh.Has_Overlap__c ? ' [OVERLAP]' : '';
                    shiftLines.add('  - ' + sh.User__r.Name + ': ' + timeRange + ' [Shift: ' + sh.Id + ']' + overlap);
                } else {
                    shiftLines.add('  - OPEN: ' + timeRange);
                }
            }

            String status = claimed < minRequired ? 'NEEDS STAFF' :
                           (claimed == sess.Shifts__r.size() ? 'FULLY STAFFED' : 'Min reached');
            String frozen = sess.Is_Frozen__c ? ' [FROZEN]' : '';

            sessionBlocks.add(sess.Name + ' (' + sess.Session_Type__r.Name + ') [ID: ' + sess.Id + '] at ' + sess.Location__c + frozen +
                '\n  Status: ' + status + ' (' + claimed + '/' + sess.Shifts__r.size() + ' shifts, min: ' + minRequired + ')' +
                '\n' + String.join(shiftLines, '\n'));
        }

        Result result = new Result();
        result.sessionCount = sessions.size();
        result.summary = sessions.isEmpty() ? 'You do not own any sessions.' :
            'You own ' + sessions.size() + ' session(s):\n\n' + String.join(sessionBlocks, '\n\n');

        return new List<Result>{ result };
    }
}
