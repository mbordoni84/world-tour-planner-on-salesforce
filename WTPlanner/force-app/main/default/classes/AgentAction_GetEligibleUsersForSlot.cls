public with sharing class AgentAction_GetEligibleUsersForSlot {

    public class Request {
        @InvocableVariable(label='Start Time' description='Shift start time in HH:MM format' required=true)
        public String startTime;
        @InvocableVariable(label='End Time' description='Shift end time in HH:MM format' required=true)
        public String endTime;
    }

    public class Result {
        @InvocableVariable(label='Available Users Summary' description='List of users available for the given time slot')
        public String summary;
        @InvocableVariable(label='User Count' description='Number of available users')
        public Integer userCount;
    }

    @InvocableMethod(label='Get Eligible Users For Slot' description='Returns users who have no scheduling conflicts for the given time slot' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        Request req = requests[0];

        Time slotStart = parseTime(req.startTime);
        Time slotEnd = parseTime(req.endTime);

        if (slotStart == null || slotEnd == null) {
            Result result = new Result();
            result.summary = 'Invalid time format. Please use HH:MM format (e.g., 09:00, 14:30).';
            result.userCount = 0;
            return new List<Result>{ result };
        }

        // Get all users with the Staffing_App_Employee permission set
        Set<Id> staffUserIds = new Set<Id>();
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'Staffing_App_Employee'
        ]) {
            staffUserIds.add(psa.AssigneeId);
        }

        // Find users who have conflicting shifts in this time slot
        Set<Id> busyUserIds = new Set<Id>();
        for (Shift__c sh : [
            SELECT User__c FROM Shift__c
            WHERE User__c IN :staffUserIds
              AND User__c != null
              AND Start_Time__c < :slotEnd
              AND End_Time__c > :slotStart
        ]) {
            busyUserIds.add(sh.User__c);
        }

        // Get available users (staff minus busy)
        Set<Id> availableIds = new Set<Id>(staffUserIds);
        availableIds.removeAll(busyUserIds);

        List<User> availableUsers = [
            SELECT Name FROM User
            WHERE Id IN :availableIds AND IsActive = true
            ORDER BY Name
        ];

        List<String> names = new List<String>();
        for (User u : availableUsers) {
            names.add('- ' + u.Name);
        }

        Result result = new Result();
        result.userCount = availableUsers.size();
        result.summary = availableUsers.isEmpty() ?
            'No users are available for the ' + req.startTime + ' - ' + req.endTime + ' time slot.' :
            availableUsers.size() + ' user(s) available for ' + req.startTime + ' - ' + req.endTime + ':\n' + String.join(names, '\n');

        return new List<Result>{ result };
    }

    private static Time parseTime(String timeStr) {
        if (String.isBlank(timeStr)) return null;
        try {
            List<String> parts = timeStr.trim().split(':');
            return Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0);
        } catch (Exception e) {
            return null;
        }
    }
}
