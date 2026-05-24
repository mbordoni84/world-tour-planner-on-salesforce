public with sharing class AgentAction_GetUserInfo {

    public class Request {
        @InvocableVariable(label='User Name' description='Name or partial name of the user to look up' required=true)
        public String userName;
    }

    public class Result {
        @InvocableVariable(label='User Info Summary' description='Complete info about the user: their shifts, owned sessions, and overlaps')
        public String summary;
        @InvocableVariable(label='Found' description='Whether a matching user was found')
        public Boolean found;
    }

    @InvocableMethod(label='Get User Info' description='Returns complete staffing info for a user: assigned shifts, owned sessions, and overlap status' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String nameInput = requests[0].userName;

        List<User> users = findUser(nameInput);

        Result result = new Result();

        if (users.isEmpty()) {
            result.summary = 'No active user found matching "' + nameInput + '".';
            result.found = false;
            return new List<Result>{ result };
        }

        User u = users[0];
        List<String> sections = new List<String>();
        sections.add('User: ' + u.Name + ' (' + u.Email + ')');

        // Assigned shifts
        List<Shift__c> shifts = [
            SELECT Start_Time__c, End_Time__c, Has_Overlap__c,
                   Session__r.Name, Session__r.Location__c, Session__r.Session_Type__r.Name
            FROM Shift__c
            WHERE User__c = :u.Id
            ORDER BY Start_Time__c
        ];

        if (shifts.isEmpty()) {
            sections.add('\nAssigned Shifts: None');
        } else {
            List<String> shiftLines = new List<String>();
            Boolean hasOverlaps = false;
            for (Shift__c sh : shifts) {
                String timeRange = StaffingAgentActions.formatTime(sh.Start_Time__c) + ' - ' +
                                   StaffingAgentActions.formatTime(sh.End_Time__c);
                String overlap = sh.Has_Overlap__c ? ' [OVERLAP]' : '';
                if (sh.Has_Overlap__c) hasOverlaps = true;
                shiftLines.add('- ' + sh.Session__r.Name + ' (' + sh.Session__r.Session_Type__r.Name + ') at ' +
                    sh.Session__r.Location__c + ', ' + timeRange + ' [Shift: ' + sh.Id + ']' + overlap);
            }
            sections.add('\nAssigned Shifts (' + shifts.size() + '):');
            sections.add(String.join(shiftLines, '\n'));
            if (hasOverlaps) {
                sections.add('WARNING: This user has scheduling overlaps!');
            }
        }

        // Owned sessions
        List<Session__c> ownedSessions = [
            SELECT Name, Location__c, Session_Type__r.Name, Min_Shifts__c,
                   (SELECT Id, User__c FROM Shifts__r)
            FROM Session__c
            WHERE session_owner__c = :u.Id
            ORDER BY Name
        ];

        if (ownedSessions.isEmpty()) {
            sections.add('\nOwned Sessions: None');
        } else {
            List<String> sessionLines = new List<String>();
            for (Session__c sess : ownedSessions) {
                Integer claimed = 0;
                for (Shift__c sh : sess.Shifts__r) {
                    if (sh.User__c != null) claimed++;
                }
                Integer minReq = sess.Min_Shifts__c != null ? (Integer)sess.Min_Shifts__c : 1;
                String status = claimed < minReq ? 'NEEDS STAFF' : 'OK';
                sessionLines.add('- ' + sess.Name + ' (' + sess.Session_Type__r.Name + ') [ID: ' + sess.Id + '] at ' +
                    sess.Location__c + ' — ' + claimed + '/' + sess.Shifts__r.size() + ' filled [' + status + ']');
            }
            sections.add('\nOwned Sessions (' + ownedSessions.size() + '):');
            sections.add(String.join(sessionLines, '\n'));
        }

        result.summary = String.join(sections, '\n');
        result.found = true;
        return new List<Result>{ result };
    }

    private static List<User> findUser(String input) {
        // Try exact match with bind variable (handles apostrophes natively)
        String pattern = '%' + input + '%';
        List<User> users = [
            SELECT Id, Name, Email FROM User
            WHERE Name LIKE :pattern AND IsActive = true
            LIMIT 1
        ];
        if (!users.isEmpty()) return users;

        // Clean special chars and try again
        String cleaned = input.replaceAll('[^a-zA-Z0-9 ]', ' ').trim().normalizeSpace();
        if (cleaned != input) {
            pattern = '%' + cleaned + '%';
            users = [
                SELECT Id, Name, Email FROM User
                WHERE Name LIKE :pattern AND IsActive = true
                LIMIT 1
            ];
            if (!users.isEmpty()) return users;
        }

        // Try word-by-word, last word first (surname more specific)
        List<String> words = cleaned.split(' ');
        List<String> searchOrder = new List<String>();
        if (words.size() > 1) {
            searchOrder.add(words[words.size() - 1]);
            for (Integer i = words.size() - 2; i >= 0; i--) {
                searchOrder.add(words[i]);
            }
        } else {
            searchOrder = words;
        }

        for (String word : searchOrder) {
            if (word.length() < 3) continue;
            pattern = '%' + word + '%';
            List<User> candidates = [
                SELECT Id, Name, Email FROM User
                WHERE Name LIKE :pattern AND IsActive = true
                LIMIT 5
            ];
            if (candidates.size() == 1) return candidates;
            // If multiple matches, pick the one matching most words from input
            if (candidates.size() > 1) {
                User bestMatch = candidates[0];
                Integer bestScore = 0;
                for (User candidate : candidates) {
                    Integer score = 0;
                    String lowerName = candidate.Name.toLowerCase();
                    for (String w : searchOrder) {
                        if (lowerName.contains(w.toLowerCase())) score++;
                    }
                    if (score > bestScore) {
                        bestScore = score;
                        bestMatch = candidate;
                    }
                }
                return new List<User>{ bestMatch };
            }
        }

        return new List<User>();
    }
}
