public with sharing class AgentAction_GetSessionStaffing {

    public class Request {
        @InvocableVariable(label='Session Name' description='Name of the session to check staffing for' required=true)
        public String sessionName;
    }

    public class Result {
        @InvocableVariable(label='Staffing Summary' description='Detailed staffing for the session including impact analysis')
        public String summary;
        @InvocableVariable(label='Total Shifts' description='Total number of shifts in the session')
        public Integer totalShifts;
        @InvocableVariable(label='Claimed Shifts' description='Number of shifts currently assigned')
        public Integer claimedShifts;
    }

    @InvocableMethod(label='Get Session Staffing' description='Returns who is staffed in a session, staffing requirements, and impact if someone is removed' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String rawInput = requests[0].sessionName.substringBefore('(').trim();

        List<Session__c> sessions = findSession(rawInput);

        Result result = new Result();

        if (sessions.isEmpty()) {
            result.summary = 'Session "' + rawInput + '" not found. Try using just the session name (e.g., "Marketing" or "Trailhead Area").';
            result.totalShifts = 0;
            result.claimedShifts = 0;
            return new List<Result>{ result };
        }

        List<String> sessionBlocks = new List<String>();
        Integer grandTotalShifts = 0;
        Integer grandClaimedShifts = 0;

        for (Session__c sess : sessions) {
            Integer minRequired = sess.Min_Shifts__c != null ? (Integer)sess.Min_Shifts__c : 1;
            Integer maxAllowed = sess.Max_Shifts__c != null ? (Integer)sess.Max_Shifts__c : 5;
            Integer totalShifts = sess.Shifts__r.size();
            Integer claimed = 0;
            List<String> staffLines = new List<String>();
            List<String> openLines = new List<String>();

            for (Shift__c sh : sess.Shifts__r) {
                String timeRange = StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                                   StaffingAgentActions.formatTime(sh.End_Time__c);
                if (sh.User__c != null) {
                    claimed++;
                    String overlap = sh.Has_Overlap__c ? ' [HAS OVERLAP]' : '';
                    staffLines.add('- ' + sh.User__r.Name + ': ' + timeRange + ' [Shift ID: ' + sh.Id + ']' + overlap);
                } else {
                    openLines.add('- OPEN: ' + timeRange);
                }
            }

            String ownerName = sess.session_owner__r != null ? sess.session_owner__r.Name : 'Not assigned';
            Boolean belowMin = claimed < minRequired;
            String impactNote = belowMin ?
                'WARNING: BELOW minimum staffing (' + claimed + '/' + minRequired + '). Removing anyone will worsen the situation.' :
                'Removing one person would ' + (claimed - 1 < minRequired ? 'drop below minimum staffing.' : 'still meet minimum requirements.');

            sessionBlocks.add('Session: ' + sess.Name + ' (' + sess.Session_Type__r.Name + ') [ID: ' + sess.Id + ']' + '\n' +
                'Location: ' + sess.Location__c + '\n' +
                'Owner: ' + ownerName + '\n' +
                'Frozen: ' + (sess.Is_Frozen__c ? 'Yes' : 'No') + '\n' +
                'Staffing: ' + claimed + '/' + totalShifts + ' shifts filled (min: ' + minRequired + ', max: ' + maxAllowed + ')\n' +
                'Assigned staff:\n' + (staffLines.isEmpty() ? '  (none)' : String.join(staffLines, '\n')) + '\n' +
                'Open shifts:\n' + (openLines.isEmpty() ? '  (none)' : String.join(openLines, '\n')) + '\n' +
                'Impact: ' + impactNote);

            grandTotalShifts += totalShifts;
            grandClaimedShifts += claimed;
        }

        String header = sessions.size() > 1 ? 'Found ' + sessions.size() + ' sessions matching "' + rawInput + '":\n\n' : '';
        result.summary = header + String.join(sessionBlocks, '\n\n---\n\n');
        result.totalShifts = grandTotalShifts;
        result.claimedShifts = grandClaimedShifts;
        return new List<Result>{ result };
    }

    private static List<Session__c> findSession(String input) {
        String searchFields = 'SELECT Name, Location__c, Min_Shifts__c, Max_Shifts__c, ' +
            'session_owner__r.Name, Is_Frozen__c, Session_Type__r.Name, ' +
            '(SELECT Id, Start_Time__c, End_Time__c, User__c, User__r.Name, Has_Overlap__c ' +
            'FROM Shifts__r ORDER BY Start_Time__c) FROM Session__c';

        // Try name match (returns all matches)
        List<Session__c> results = Database.query(
            searchFields + ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(input) + '%\' ORDER BY Name LIMIT 10',
            AccessLevel.USER_MODE
        );
        if (!results.isEmpty()) return results;

        // Try session type match
        results = Database.query(
            searchFields + ' WHERE Session_Type__r.Name LIKE \'%' + String.escapeSingleQuotes(input) + '%\' ORDER BY Name LIMIT 10',
            AccessLevel.USER_MODE
        );
        if (!results.isEmpty()) return results;

        // Split words and try each
        for (String word : input.split('\\s+')) {
            if (word.length() < 3) continue;
            results = Database.query(
                searchFields + ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(word) + '%\' ORDER BY Name LIMIT 10',
                AccessLevel.USER_MODE
            );
            if (!results.isEmpty()) return results;
        }

        return new List<Session__c>();
    }
}
