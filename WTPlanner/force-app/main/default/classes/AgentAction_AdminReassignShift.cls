public with sharing class AgentAction_AdminReassignShift {

    public class Request {
        @InvocableVariable(label='Session Name' description='Name of the session containing the shift' required=true)
        public String sessionName;
        @InvocableVariable(label='Current User Name' description='Name of the user currently assigned to the shift' required=true)
        public String currentUserName;
        @InvocableVariable(label='New User Name' description='Name of the user to reassign the shift to' required=true)
        public String newUserName;
        @InvocableVariable(label='Confirmed' description='Set to true to execute the reassignment, false to preview only' required=true)
        public Boolean confirmed;
    }

    public class Result {
        @InvocableVariable(label='Message' description='Result of the reassignment operation')
        public String message;
        @InvocableVariable(label='Success' description='Whether the operation succeeded')
        public Boolean success;
    }

    @InvocableMethod(label='Admin Reassign Shift' description='Reassigns a shift from one user to another. Requires admin permissions. Use confirmed=false for preview.' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        Request req = requests[0];
        Result result = new Result();

        // Find the shift
        String sessName = req.sessionName.substringBefore('(').trim();
        List<Shift__c> shifts = [
            SELECT Id, Start_Time__c, End_Time__c, User__c, User__r.Name,
                   Session__r.Name, Session__r.Is_Frozen__c
            FROM Shift__c
            WHERE Session__r.Name LIKE :('%' + sessName + '%')
              AND User__r.Name LIKE :('%' + String.escapeSingleQuotes(req.currentUserName) + '%')
            LIMIT 1
        ];

        if (shifts.isEmpty()) {
            result.message = 'Could not find a shift for "' + req.currentUserName + '" in session "' + sessName + '".';
            result.success = false;
            return new List<Result>{ result };
        }

        Shift__c shift = shifts[0];

        if (shift.Session__r.Is_Frozen__c) {
            result.message = 'Cannot reassign: session "' + shift.Session__r.Name + '" is frozen.';
            result.success = false;
            return new List<Result>{ result };
        }

        // Find the new user
        List<User> newUsers = [
            SELECT Id, Name FROM User
            WHERE Name LIKE :('%' + String.escapeSingleQuotes(req.newUserName) + '%')
              AND IsActive = true
            LIMIT 1
        ];

        if (newUsers.isEmpty()) {
            result.message = 'Could not find an active user matching "' + req.newUserName + '".';
            result.success = false;
            return new List<Result>{ result };
        }

        User newUser = newUsers[0];
        String timeRange = StaffingAgentActions.formatTime(shift.Start_Time__c) + ' - ' +
                           StaffingAgentActions.formatTime(shift.End_Time__c);

        if (!req.confirmed) {
            result.message = 'Preview: Reassign shift ' + timeRange + ' in "' + shift.Session__r.Name +
                '" from ' + shift.User__r.Name + ' to ' + newUser.Name + '. Please confirm to proceed.';
            result.success = true;
            return new List<Result>{ result };
        }

        // Execute reassignment
        shift.User__c = newUser.Id;
        try {
            update shift;
            result.message = 'Successfully reassigned shift ' + timeRange + ' in "' + shift.Session__r.Name +
                '" from ' + req.currentUserName + ' to ' + newUser.Name + '.';
            result.success = true;
        } catch (Exception e) {
            result.message = 'Failed to reassign: ' + e.getMessage();
            result.success = false;
        }

        return new List<Result>{ result };
    }
}
