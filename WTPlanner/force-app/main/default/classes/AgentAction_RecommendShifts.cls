public with sharing class AgentAction_RecommendShifts {

    public class Request {
        @InvocableVariable(label='Session Type Filter' description='Optional: filter recommendations by session type' required=false)
        public String sessionTypeFilter;
    }

    public class Result {
        @InvocableVariable(label='Recommendations Summary' description='Smart shift recommendations that avoid overlaps')
        public String summary;
        @InvocableVariable(label='Recommendation Count' description='Number of recommendations')
        public Integer recommendationCount;
    }

    @InvocableMethod(label='Recommend Shifts' description='Suggests shifts the user should claim based on staffing urgency and overlap avoidance' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String typeFilter = requests[0].sessionTypeFilter;
        Id currentUserId = UserInfo.getUserId();

        // Get user's current shifts for overlap checking
        List<Shift__c> myShifts = [
            SELECT Start_Time__c, End_Time__c FROM Shift__c
            WHERE User__c = :currentUserId
        ];

        // Get sessions with available shifts
        String query = 'SELECT Name, Location__c, Min_Shifts__c, Session_Type__r.Name, ' +
            '(SELECT Id, Start_Time__c, End_Time__c, User__c FROM Shifts__r ORDER BY Start_Time__c) ' +
            'FROM Session__c WHERE Is_Frozen__c = false';

        if (String.isNotBlank(typeFilter)) {
            query += ' AND Session_Type__r.Name LIKE \'%' + String.escapeSingleQuotes(typeFilter) + '%\'';
        }
        query += ' ORDER BY Name';

        List<Session__c> sessions = Database.query(query, AccessLevel.USER_MODE);

        List<Recommendation> recommendations = new List<Recommendation>();

        for (Session__c sess : sessions) {
            Integer minRequired = sess.Min_Shifts__c != null ? (Integer)sess.Min_Shifts__c : 1;
            Integer claimed = 0;
            List<Shift__c> openShifts = new List<Shift__c>();

            for (Shift__c sh : sess.Shifts__r) {
                if (sh.User__c != null) {
                    claimed++;
                } else {
                    openShifts.add(sh);
                }
            }

            if (openShifts.isEmpty()) continue;

            Integer staffingGap = minRequired - claimed;
            if (staffingGap <= 0) continue; // Only recommend sessions that NEED staff

            for (Shift__c openShift : openShifts) {
                Boolean wouldOverlap = false;
                for (Shift__c myShift : myShifts) {
                    if (myShift.Start_Time__c < openShift.End_Time__c &&
                        myShift.End_Time__c > openShift.Start_Time__c) {
                        wouldOverlap = true;
                        break;
                    }
                }

                if (!wouldOverlap) {
                    recommendations.add(new Recommendation(
                        sess.Name, sess.Session_Type__r.Name, sess.Location__c,
                        openShift.Start_Time__c, openShift.End_Time__c,
                        staffingGap, minRequired
                    ));
                    break; // One recommendation per session
                }
            }
        }

        // Sort by urgency (biggest staffing gap first)
        recommendations.sort();

        List<String> lines = new List<String>();
        Integer maxRecs = Math.min(5, recommendations.size());
        for (Integer i = 0; i < maxRecs; i++) {
            Recommendation rec = recommendations[i];
            String timeRange = StaffingAgentActions.formatTime(rec.startTime) + ' - ' +
                               StaffingAgentActions.formatTime(rec.endTime);
            lines.add((i + 1) + '. ' + rec.sessionName + ' | Type: ' + rec.sessionType + ' | Location: ' + rec.location +
                '\n   Time: ' + timeRange +
                '\n   Reason: Needs ' + rec.staffingGap + ' more staff (min: ' + rec.minRequired + '). No overlap with your schedule.');
        }

        Result result = new Result();
        result.recommendationCount = maxRecs;
        result.summary = lines.isEmpty() ?
            'No recommendations available — either all sessions are fully staffed or all open shifts would conflict with your schedule.' :
            'Top recommendations (no overlap with your schedule):\n\n' + String.join(lines, '\n\n');

        return new List<Result>{ result };
    }

    private class Recommendation implements Comparable {
        public String sessionName;
        public String sessionType;
        public String location;
        public Time startTime;
        public Time endTime;
        public Integer staffingGap;
        public Integer minRequired;

        public Recommendation(String name, String type, String loc, Time start, Time endT, Integer gap, Integer min) {
            this.sessionName = name;
            this.sessionType = type;
            this.location = loc;
            this.startTime = start;
            this.endTime = endT;
            this.staffingGap = gap;
            this.minRequired = min;
        }

        public Integer compareTo(Object other) {
            Recommendation o = (Recommendation)other;
            return o.staffingGap - this.staffingGap; // Descending by gap
        }
    }
}
