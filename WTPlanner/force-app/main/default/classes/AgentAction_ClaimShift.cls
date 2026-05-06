public with sharing class AgentAction_ClaimShift {

    public class Request {
        @InvocableVariable(label='Session Name' description='Name of the session to claim a shift for' required=true)
        public String sessionName;
    }

    public class Result {
        @InvocableVariable(label='Result Message' description='Result of the claim operation')
        public String message;
        @InvocableVariable(label='Success' description='Whether the claim was successful')
        public Boolean success;
    }

    @InvocableMethod(label='Claim Shift' description='Claims the first available shift for a given session name. Assigns it to the current user.' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String sessionName = requests[0].sessionName;
        // Strip session type in parentheses that the agent may append, e.g. "Name (Type)"
        if (sessionName != null && sessionName.contains('(')) {
            sessionName = sessionName.substringBefore('(').trim();
        }
        Result result = new Result();

        try {
            List<Session__c> sessions = [
                SELECT Id, Name, Is_Frozen__c, Session_Type__r.Is_Frozen__c FROM Session__c
                WHERE Name LIKE :('%' + sessionName + '%')
                LIMIT 1
            ];

            if (sessions.isEmpty()) {
                result.success = false;
                result.message = 'No session found matching "' + sessionName + '".';
                return new List<Result>{ result };
            }

            Session__c foundSession = sessions[0];
            if (foundSession.Is_Frozen__c || (foundSession.Session_Type__r != null && foundSession.Session_Type__r.Is_Frozen__c)) {
                result.success = false;
                result.message = 'Session "' + foundSession.Name + '" is currently frozen. You cannot claim shifts.';
                return new List<Result>{ result };
            }

            List<Shift__c> availableShifts = [
                SELECT Id, Start_Time__c, End_Time__c
                FROM Shift__c
                WHERE Session__c = :sessions[0].Id
                  AND User__c = null
                ORDER BY Start_Time__c
                LIMIT 1
            ];

            if (availableShifts.isEmpty()) {
                result.success = false;
                result.message = 'No available shifts for session "' + sessions[0].Name + '".';
                return new List<Result>{ result };
            }

            Shift__c shift = availableShifts[0];
            shift.User__c = UserInfo.getUserId();
            update shift;

            result.success = true;
            result.message = 'Successfully claimed shift ' +
                             StaffingAgentActions.formatTime(shift.Start_Time__c) + ' - ' +
                             StaffingAgentActions.formatTime(shift.End_Time__c) +
                             ' for session "' + sessions[0].Name + '".';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error claiming shift: ' + e.getMessage();
        }

        return new List<Result>{ result };
    }
}
