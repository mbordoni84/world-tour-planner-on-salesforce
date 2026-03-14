public with sharing class AdminRosterController {

    @AuraEnabled(cacheable=true)
    public static RosterData getRosterData() {
        try {
            // Query all shifts (assigned + unassigned) with full session details
            List<Shift__c> allShifts = [
                SELECT Id, Name, Start_Time__c, End_Time__c,
                       User__c, User__r.Name, Has_Overlap__c,
                       Session__c, Session__r.Name, Session__r.Location__c,
                       Session__r.Session_Type__r.Name,
                       Session__r.Min_Shifts__c, Session__r.Max_Shifts__c
                FROM Shift__c
                ORDER BY Start_Time__c
            ];

            // Build staffing counts and overlap flags per session
            Map<Id, Integer> claimedBySession = new Map<Id, Integer>();
            Map<Id, Integer> totalBySession = new Map<Id, Integer>();
            Map<Id, Boolean> overlapBySession = new Map<Id, Boolean>();
            Set<String> sessionTypeSet = new Set<String>();
            Set<String> sessionNameSet = new Set<String>();
            Set<String> timeSlotSet = new Set<String>();

            for (Shift__c shift : allShifts) {
                Id sessId = shift.Session__c;
                totalBySession.put(sessId, (totalBySession.containsKey(sessId) ? totalBySession.get(sessId) : 0) + 1);
                if (shift.User__c != null) {
                    claimedBySession.put(sessId, (claimedBySession.containsKey(sessId) ? claimedBySession.get(sessId) : 0) + 1);
                }
                if (shift.Has_Overlap__c && shift.User__c != null) {
                    overlapBySession.put(sessId, true);
                }
                if (!overlapBySession.containsKey(sessId)) {
                    overlapBySession.put(sessId, false);
                }
                timeSlotSet.add(formatTimeSlot(shift.Start_Time__c, shift.End_Time__c));
                if (shift.Session__r.Session_Type__r.Name != null) {
                    sessionTypeSet.add(shift.Session__r.Session_Type__r.Name);
                }
                if (shift.Session__r.Name != null) {
                    sessionNameSet.add(shift.Session__r.Name);
                }
            }

            // Build "By Person" rows
            List<String> timeSlots = new List<String>(timeSlotSet);
            timeSlots.sort();

            Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
            Set<Id> userIds = new Set<Id>();
            for (Shift__c shift : allShifts) {
                if (shift.User__c != null) {
                    userIds.add(shift.User__c);
                    if (!shiftsByUser.containsKey(shift.User__c)) {
                        shiftsByUser.put(shift.User__c, new List<Shift__c>());
                    }
                    shiftsByUser.get(shift.User__c).add(shift);
                }
            }

            Map<Id, User> usersMap = new Map<Id, User>([
                SELECT Id, Name FROM User WHERE Id IN :userIds ORDER BY Name
            ]);

            List<RosterRow> rows = new List<RosterRow>();
            for (Id userId : usersMap.keySet()) {
                List<Shift__c> userShifts = shiftsByUser.get(userId);
                if (userShifts == null) continue;

                Map<String, String> cellData = new Map<String, String>();
                Map<String, CellDetail> cellDetails = new Map<String, CellDetail>();

                for (Shift__c shift : userShifts) {
                    String timeSlot = formatTimeSlot(shift.Start_Time__c, shift.End_Time__c);
                    cellData.put(timeSlot, shift.Session__r.Name);

                    Id sessId = shift.Session__c;
                    Integer claimed = claimedBySession.containsKey(sessId) ? claimedBySession.get(sessId) : 0;
                    Integer minS = shift.Session__r.Min_Shifts__c != null ? (Integer)shift.Session__r.Min_Shifts__c : 1;
                    Integer maxS = shift.Session__r.Max_Shifts__c != null ? (Integer)shift.Session__r.Max_Shifts__c : 5;
                    String staffStatus = claimed < minS ? 'Needs Staff' : (claimed >= maxS ? 'Fully Staffed' : 'Min Reached');
                    Boolean hasSessionOverlap = overlapBySession.containsKey(sessId) && overlapBySession.get(sessId);

                    CellDetail detail = new CellDetail();
                    detail.sessionName = shift.Session__r.Name;
                    detail.sessionType = shift.Session__r.Session_Type__r.Name != null ? shift.Session__r.Session_Type__r.Name : '';
                    detail.timeRange = formatHHMM(shift.Start_Time__c) + ' - ' + formatHHMM(shift.End_Time__c);
                    detail.location = shift.Session__r.Location__c != null ? shift.Session__r.Location__c : '';
                    detail.staffingLabel = claimed + '/' + minS + ' min (' + maxS + ' max)';
                    detail.status = staffStatus;
                    detail.minReached = claimed >= minS;
                    detail.hasOverlap = shift.Has_Overlap__c;
                    detail.sessionHasOverlap = hasSessionOverlap;
                    cellDetails.put(timeSlot, detail);
                }

                rows.add(new RosterRow(usersMap.get(userId).Name, cellData, cellDetails));
            }

            // Build "By Shift" wrappers
            List<ShiftRosterWrapper> shiftWrappers = new List<ShiftRosterWrapper>();
            for (Shift__c shift : allShifts) {
                Id sessId = shift.Session__c;
                Integer claimed = claimedBySession.containsKey(sessId) ? claimedBySession.get(sessId) : 0;
                Integer minS = shift.Session__r.Min_Shifts__c != null ? (Integer)shift.Session__r.Min_Shifts__c : 1;
                Integer maxS = shift.Session__r.Max_Shifts__c != null ? (Integer)shift.Session__r.Max_Shifts__c : 5;
                Boolean sessionOverlap = overlapBySession.containsKey(sessId) && overlapBySession.get(sessId);
                shiftWrappers.add(new ShiftRosterWrapper(shift, claimed >= minS, sessionOverlap));
            }

            // Build filter options
            List<String> sortedTypes = new List<String>(sessionTypeSet);
            sortedTypes.sort();
            List<String> sortedNames = new List<String>(sessionNameSet);
            sortedNames.sort();
            List<String> sortedSlots = new List<String>(timeSlotSet);
            sortedSlots.sort();

            RosterData data = new RosterData();
            data.timeSlots = timeSlots;
            data.rows = rows;
            data.shifts = shiftWrappers;
            data.sessionTypes = sortedTypes;
            data.sessionNames = sortedNames;
            data.timeSlotOptions = sortedSlots;
            return data;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching roster: ' + e.getMessage());
        }
    }

    private static String formatHHMM(Time t) {
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
               String.valueOf(t.minute()).leftPad(2, '0');
    }

    private static String formatTimeSlot(Time startTime, Time endTime) {
        return String.valueOf(startTime).substring(0, 5) + '-' +
               String.valueOf(endTime).substring(0, 5);
    }

    public class RosterData {
        @AuraEnabled public List<String> timeSlots {get; set;}
        @AuraEnabled public List<RosterRow> rows {get; set;}
        @AuraEnabled public List<ShiftRosterWrapper> shifts {get; set;}
        @AuraEnabled public List<String> sessionTypes {get; set;}
        @AuraEnabled public List<String> sessionNames {get; set;}
        @AuraEnabled public List<String> timeSlotOptions {get; set;}
    }

    public class RosterRow {
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public Map<String, String> cells {get; set;}
        @AuraEnabled public Map<String, CellDetail> cellDetails {get; set;}

        public RosterRow(String userName, Map<String, String> cells, Map<String, CellDetail> cellDetails) {
            this.userName = userName;
            this.cells = cells;
            this.cellDetails = cellDetails;
        }
    }

    public class CellDetail {
        @AuraEnabled public String sessionName {get; set;}
        @AuraEnabled public String sessionType {get; set;}
        @AuraEnabled public String timeRange {get; set;}
        @AuraEnabled public String location {get; set;}
        @AuraEnabled public String staffingLabel {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Boolean minReached {get; set;}
        @AuraEnabled public Boolean hasOverlap {get; set;}
        @AuraEnabled public Boolean sessionHasOverlap {get; set;}
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
        @AuraEnabled public Boolean minReached {get; set;}
        @AuraEnabled public Boolean sessionHasOverlap {get; set;}

        public ShiftRosterWrapper(Shift__c shift, Boolean minReached, Boolean sessionHasOverlap) {
            this.id = shift.Id;
            this.name = shift.Name;
            this.timeSlot = formatTimeSlot(shift.Start_Time__c, shift.End_Time__c);
            this.sessionName = shift.Session__r.Name;
            this.sessionType = shift.Session__r.Session_Type__r.Name;
            this.sessionLocation = shift.Session__r.Location__c;
            this.assignedUserName = shift.User__r?.Name;
            this.hasOverlap = shift.Has_Overlap__c;
            this.isAssigned = shift.User__c != null;
            this.minReached = minReached;
            this.sessionHasOverlap = sessionHasOverlap;
        }
    }
}
