public with sharing class AdminRosterController {

    @AuraEnabled(cacheable=true)
    public static RosterByPersonData getRosterByPerson() {
        try {
            List<Shift__c> allShifts = [
                SELECT Id, Name, Start_Time__c, End_Time__c,
                       Session__r.Session_Type__r.Name
                FROM Shift__c
                ORDER BY Start_Time__c
            ];

            List<Shift__c> assignedShifts = [
                SELECT Id, User__c, User__r.Name,
                       Start_Time__c, End_Time__c,
                       Session__r.Name, Session__r.Session_Type__r.Name,
                       Session__r.Location__c, Session__r.Min_Shifts__c, Session__r.Max_Shifts__c
                FROM Shift__c
                WHERE User__c != null
                ORDER BY User__r.Name, Start_Time__c
            ];

            // Build staffing counts per session
            Map<Id, Integer> claimedBySession = new Map<Id, Integer>();
            for (Shift__c shift : assignedShifts) {
                Id sessId = shift.Session__c;
                claimedBySession.put(sessId, (claimedBySession.containsKey(sessId) ? claimedBySession.get(sessId) : 0) + 1);
            }

            Set<String> timeSlotSet = new Set<String>();
            for (Shift__c shift : allShifts) {
                timeSlotSet.add(formatTimeSlot(shift.Start_Time__c, shift.End_Time__c));
            }
            List<String> timeSlots = new List<String>(timeSlotSet);
            timeSlots.sort();

            Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
            Set<Id> userIds = new Set<Id>();
            for (Shift__c shift : assignedShifts) {
                userIds.add(shift.User__c);
                if (!shiftsByUser.containsKey(shift.User__c)) {
                    shiftsByUser.put(shift.User__c, new List<Shift__c>());
                }
                shiftsByUser.get(shift.User__c).add(shift);
            }

            Map<Id, User> usersMap = new Map<Id, User>([
                SELECT Id, Name FROM User WHERE Id IN :userIds ORDER BY Name
            ]);

            List<RosterRow> rows = new List<RosterRow>();
            for (Id userId : usersMap.keySet()) {
                List<Shift__c> userShifts = shiftsByUser.get(userId);
                if (userShifts == null) {
                    userShifts = new List<Shift__c>();
                }

                Map<String, String> cellData = new Map<String, String>();
                Map<String, String> cellTooltips = new Map<String, String>();
                for (Shift__c shift : userShifts) {
                    String timeSlot = formatTimeSlot(shift.Start_Time__c, shift.End_Time__c);
                    cellData.put(timeSlot, shift.Session__r.Name);

                    Integer claimed = claimedBySession.containsKey(shift.Session__c) ? claimedBySession.get(shift.Session__c) : 0;
                    Integer minS = shift.Session__r.Min_Shifts__c != null ? (Integer)shift.Session__r.Min_Shifts__c : 1;
                    Integer maxS = shift.Session__r.Max_Shifts__c != null ? (Integer)shift.Session__r.Max_Shifts__c : 5;
                    String staffStatus = claimed < minS ? 'Needs Staff' : (claimed >= maxS ? 'Fully Staffed' : 'Min Reached');
                    String loc = shift.Session__r.Location__c != null ? shift.Session__r.Location__c : '';

                    String tooltip = shift.Session__r.Name +
                        '\nType: ' + (shift.Session__r.Session_Type__r.Name != null ? shift.Session__r.Session_Type__r.Name : '') +
                        '\nTime: ' + String.valueOf(shift.Start_Time__c) + ' - ' + String.valueOf(shift.End_Time__c) +
                        '\nLocation: ' + loc +
                        '\nStaffing: ' + claimed + '/' + minS + ' min (' + maxS + ' max)' +
                        '\nStatus: ' + staffStatus;
                    cellTooltips.put(timeSlot, tooltip);
                }

                rows.add(new RosterRow(usersMap.get(userId).Name, cellData, cellTooltips));
            }

            return new RosterByPersonData(timeSlots, rows);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching roster: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ShiftRosterWrapper> getRosterByShift() {
        try {
            List<Shift__c> shifts = [
                SELECT Id, Name, Start_Time__c, End_Time__c,
                       User__c, User__r.Name, Has_Overlap__c,
                       Session__r.Name, Session__r.Location__c,
                       Session__r.Session_Type__r.Name
                FROM Shift__c
                ORDER BY Start_Time__c
            ];

            List<ShiftRosterWrapper> wrappers = new List<ShiftRosterWrapper>();
            for (Shift__c shift : shifts) {
                wrappers.add(new ShiftRosterWrapper(shift));
            }

            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching shift roster: ' + e.getMessage());
        }
    }

    private static String formatTimeSlot(Time startTime, Time endTime) {
        return String.valueOf(startTime).substring(0, 5) + '-' +
               String.valueOf(endTime).substring(0, 5);
    }

    public class RosterByPersonData {
        @AuraEnabled public List<String> timeSlots {get; set;}
        @AuraEnabled public List<RosterRow> rows {get; set;}

        public RosterByPersonData(List<String> timeSlots, List<RosterRow> rows) {
            this.timeSlots = timeSlots;
            this.rows = rows;
        }
    }

    public class RosterRow {
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public Map<String, String> cells {get; set;}
        @AuraEnabled public Map<String, String> tooltips {get; set;}

        public RosterRow(String userName, Map<String, String> cells, Map<String, String> tooltips) {
            this.userName = userName;
            this.cells = cells;
            this.tooltips = tooltips;
        }
    }

    public class ShiftRosterWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String timeSlot {get; set;}
        @AuraEnabled public String sessionName {get; set;}
        @AuraEnabled public String sessionType {get; set;}
        @AuraEnabled public String sessionLocation {get; set;}
        @AuraEnabled public String assignedUserName {get; set;}
        @AuraEnabled public Boolean hasOverlap {get; set;}
        @AuraEnabled public Boolean isAssigned {get; set;}

        public ShiftRosterWrapper(Shift__c shift) {
            this.id = shift.Id;
            this.name = shift.Name;
            this.timeSlot = formatTimeSlot(shift.Start_Time__c, shift.End_Time__c);
            this.sessionName = shift.Session__r.Name;
            this.sessionType = shift.Session__r.Session_Type__r.Name;
            this.sessionLocation = shift.Session__r.Location__c;
            this.assignedUserName = shift.User__r?.Name;
            this.hasOverlap = shift.Has_Overlap__c;
            this.isAssigned = shift.User__c != null;
        }
    }
}
