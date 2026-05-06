public with sharing class AgentAction_DropShift {

    public class Request {
        @InvocableVariable(label='Session Name' description='Name of the session to drop a shift from' required=true)
        public String sessionName;
    }

    public class Result {
        @InvocableVariable(label='Result Message' description='Result of the drop operation')
        public String message;
        @InvocableVariable(label='Success' description='Whether the drop was successful')
        public Boolean success;
    }

    @InvocableMethod(label='Drop Shift' description='Drops (unassigns) the current user shift for a given session name' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        String sessionName = requests[0].sessionName;
        // Strip session type in parentheses that the agent may append, e.g. "Name (Type)"
        if (sessionName != null && sessionName.contains('(')) {
            sessionName = sessionName.substringBefore('(').trim();
        }
        Result result = new Result();

        try {
            List<Shift__c> myShifts = [
                SELECT Id, Start_Time__c, End_Time__c, Session__c,
                       Session__r.Name, Session__r.Is_Frozen__c, Session__r.Session_Type__r.Is_Frozen__c
                FROM Shift__c
                WHERE User__c = :UserInfo.getUserId()
                  AND Session__r.Name LIKE :('%' + sessionName + '%')
                LIMIT 1
            ];

            if (myShifts.isEmpty()) {
                result.success = false;
                result.message = 'You have no shifts assigned for a session matching "' + sessionName + '".';
                return new List<Result>{ result };
            }

            Shift__c shift = myShifts[0];
            if (shift.Session__r.Is_Frozen__c || (shift.Session__r.Session_Type__r != null && shift.Session__r.Session_Type__r.Is_Frozen__c)) {
                result.success = false;
                result.message = 'Session "' + shift.Session__r.Name + '" is currently frozen. You cannot drop shifts.';
                return new List<Result>{ result };
            }

            shift.User__c = null;
            update shift;

            result.success = true;
            result.message = 'Successfully dropped your shift (' +
                             StaffingAgentActions.formatTime(shift.Start_Time__c) + ' - ' +
                             StaffingAgentActions.formatTime(shift.End_Time__c) +
                             ') from session "' + shift.Session__r.Name + '".';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error dropping shift: ' + e.getMessage();
        }

        return new List<Result>{ result };
    }
}
