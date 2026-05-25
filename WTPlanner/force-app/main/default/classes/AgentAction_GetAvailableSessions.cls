public with sharing class AgentAction_GetAvailableSessions {

    public class Request {
        @InvocableVariable(label='Session Type Filter' description='Optional: filter by session type name (e.g. Booth, Keynote)' required=false)
        public String sessionTypeFilter;
    }

    public class Result {
        @InvocableVariable(label='Sessions Summary' description='Summary of available sessions')
        public String summary;
        @InvocableVariable(label='Session Count' description='Number of sessions found')
        public Integer sessionCount;
    }

    @InvocableMethod(label='Get Available Sessions' description='Returns sessions that still have unclaimed shifts available for staffing' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String filter = requests[0].sessionTypeFilter;
        Id currentUserId = UserInfo.getUserId();

        // Query user's existing shifts for overlap detection
        Map<Id, Shift__c> myShiftsBySession = new Map<Id, Shift__c>();
        List<Shift__c> myShifts = [
            SELECT Id, Start_Time__c, End_Time__c, Session__c, Session__r.Name
            FROM Shift__c
            WHERE User__c = :currentUserId
            ORDER BY Start_Time__c
        ];

        String query = 'SELECT Name, Location__c, Session_Type__r.Name, Min_Shifts__c, Max_Shifts__c, ' +
                       'Is_Frozen__c, Session_Type__r.Is_Frozen__c, ' +
                       '(SELECT Id, Start_Time__c, End_Time__c, User__c FROM Shifts__r ORDER BY Start_Time__c) ' +
                       'FROM Session__c';

        if (String.isNotBlank(filter)) {
            query += ' WHERE Session_Type__r.Name = :filter';
        }
        query += ' ORDER BY Name';

        List<Session__c> sessions = Database.query(query);

        List<String> lines = new List<String>();
        Integer count = 0;

        for (Session__c s : sessions) {
            if (s.Is_Frozen__c || (s.Session_Type__r != null && s.Session_Type__r.Is_Frozen__c)) {
                continue;
            }
            List<String> availableShiftTimes = new List<String>();

            Map<String, Integer> claimedBySlot = new Map<String, Integer>();
            Map<String, Integer> totalBySlot = new Map<String, Integer>();

            for (Shift__c sh : s.Shifts__r) {
                String slotKey = String.valueOf(sh.Start_Time__c) + '-' + String.valueOf(sh.End_Time__c);
                totalBySlot.put(slotKey, (totalBySlot.containsKey(slotKey) ? totalBySlot.get(slotKey) : 0) + 1);
                if (sh.User__c != null) {
                    claimedBySlot.put(slotKey, (claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0) + 1);
                } else {
                    String timeStr = StaffingAgentActions.formatTime(sh.Start_Time__c) + '-' +
                                     StaffingAgentActions.formatTime(sh.End_Time__c) +
                                     ' [Shift ID: ' + sh.Id + ']';
                    String overlapWarning = getOverlapWarning(sh, myShifts);
                    if (String.isNotBlank(overlapWarning)) {
                        timeStr += ' ' + overlapWarning;
                    }
                    availableShiftTimes.add(timeStr);
                }
            }

            if (!availableShiftTimes.isEmpty()) {
                Integer minNeeded = s.Min_Shifts__c != null ? (Integer)s.Min_Shifts__c : 1;
                Boolean anySlotNeedsStaff = false;
                Integer worstClaimed = minNeeded;
                for (String slotKey : totalBySlot.keySet()) {
                    Integer slotClaimed = claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0;
                    if (slotClaimed < minNeeded) {
                        anySlotNeedsStaff = true;
                        worstClaimed = Math.min(worstClaimed, slotClaimed);
                    }
                }

                String staffingInfo = worstClaimed + '/' + minNeeded + ' min per slot';
                if (anySlotNeedsStaff) {
                    staffingInfo += ' — NEEDS STAFF';
                } else {
                    staffingInfo += ' reached';
                }

                String line = '- ' + s.Name + ' [ID: ' + s.Id + '] | Type: ' + s.Session_Type__r.Name + ' | Location: ' + s.Location__c +
                              ' | Staffing: ' + staffingInfo + '\n' +
                              '  Available shifts: ' + String.join(availableShiftTimes, ', ');
                lines.add(line);
                count++;
            }
        }

        Result result = new Result();
        result.sessionCount = count;
        result.summary = count == 0 ? 'No sessions with available shifts found.' :
                         'Found ' + count + ' session(s) with available shifts:\n\n' + String.join(lines, '\n\n');

        return new List<Result>{ result };
    }

    private static String getOverlapWarning(Shift__c availableShift, List<Shift__c> userShifts) {
        for (Shift__c my : userShifts) {
            if (my.Start_Time__c != null && my.End_Time__c != null &&
                availableShift.Start_Time__c != null && availableShift.End_Time__c != null &&
                my.Start_Time__c < availableShift.End_Time__c &&
                my.End_Time__c > availableShift.Start_Time__c) {
                return '[OVERLAP with your ' + my.Session__r.Name + ' ' +
                       StaffingAgentActions.formatTime(my.Start_Time__c) + '-' +
                       StaffingAgentActions.formatTime(my.End_Time__c) + ']';
            }
        }
        return null;
    }
}
