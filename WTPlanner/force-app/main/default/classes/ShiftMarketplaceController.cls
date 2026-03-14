public with sharing class ShiftMarketplaceController {

    @AuraEnabled(cacheable=true)
    public static List<SessionWrapper> getSessionsNeedingStaff() {
        try {
            List<Session__c> sessions = [
                SELECT Id, Name, Location__c, Description__c,
                       Min_Shifts__c, Max_Shifts__c,
                       Session_Type__r.Name,
                       (SELECT Id, Name, Start_Time__c, End_Time__c,
                               User__c, User__r.Name, Has_Overlap__c
                        FROM Shifts__r
                        ORDER BY Start_Time__c)
                FROM Session__c
                ORDER BY Name
            ];

            List<SessionWrapper> wrappers = new List<SessionWrapper>();
            for (Session__c session : sessions) {
                wrappers.add(new SessionWrapper(session));
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sessions: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ShiftWrapper> getMyShifts() {
        try {
            List<Shift__c> shifts = [
                SELECT Id, Name, Start_Time__c, End_Time__c,
                       User__c, User__r.Name, Has_Overlap__c,
                       Session__r.Name, Session__r.Location__c,
                       Session__r.Description__c,
                       Session__r.Session_Type__r.Name
                FROM Shift__c
                WHERE User__c = :UserInfo.getUserId()
                ORDER BY Start_Time__c
            ];

            List<ShiftWrapper> wrappers = new List<ShiftWrapper>();
            for (Shift__c shift : shifts) {
                wrappers.add(new ShiftWrapper(shift));
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching my shifts: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String claimShift(String shiftId) {
        try {
            Shift__c shift = [
                SELECT Id, User__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            if (shift.User__c != null) {
                AuraHandledException ex = new AuraHandledException('This shift is already claimed');
                ex.setMessage('This shift is already claimed');
                throw ex;
            }

            shift.User__c = UserInfo.getUserId();
            update shift;

            return shift.Id;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error claiming shift: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String quickAssign(String sessionId) {
        try {
            // Find the first unclaimed shift for this session
            List<Shift__c> availableShifts = [
                SELECT Id, User__c
                FROM Shift__c
                WHERE Session__c = :sessionId
                  AND User__c = null
                ORDER BY Start_Time__c
                LIMIT 1
            ];

            if (availableShifts.isEmpty()) {
                // Check if we can add a new shift
                Session__c session = [
                    SELECT Id, Max_Shifts__c,
                           (SELECT Id FROM Shifts__r)
                    FROM Session__c
                    WHERE Id = :sessionId
                    LIMIT 1
                ];

                Integer currentCount = session.Shifts__r.size();
                Decimal maxShifts = session.Max_Shifts__c != null ? session.Max_Shifts__c : 999;

                if (currentCount >= maxShifts) {
                    AuraHandledException ex = new AuraHandledException('This session has reached its maximum number of shifts');
                    ex.setMessage('This session has reached its maximum number of shifts');
                    throw ex;
                }

                // Get a representative shift to copy time from
                List<Shift__c> existingShifts = [
                    SELECT Start_Time__c, End_Time__c
                    FROM Shift__c
                    WHERE Session__c = :sessionId
                    ORDER BY Start_Time__c
                    LIMIT 1
                ];

                Shift__c newShift = new Shift__c(
                    Session__c = sessionId,
                    User__c = UserInfo.getUserId(),
                    Start_Time__c = existingShifts.isEmpty() ?
                        Time.newInstance(9, 0, 0, 0) : existingShifts[0].Start_Time__c,
                    End_Time__c = existingShifts.isEmpty() ?
                        Time.newInstance(17, 0, 0, 0) : existingShifts[0].End_Time__c
                );
                insert newShift;
                return newShift.Id;
            }

            Shift__c shift = availableShifts[0];
            shift.User__c = UserInfo.getUserId();
            update shift;
            return shift.Id;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning to session: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void dropShift(String shiftId) {
        try {
            Shift__c shift = [
                SELECT Id, User__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            if (shift.User__c != UserInfo.getUserId()) {
                AuraHandledException ex = new AuraHandledException('You can only drop your own shifts');
                ex.setMessage('You can only drop your own shifts');
                throw ex;
            }

            shift.User__c = null;
            update shift;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error dropping shift: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static OverlapCheckResult checkOverlap(String shiftId) {
        try {
            Shift__c shift = [
                SELECT Start_Time__c, End_Time__c, Session__r.Name
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            List<Shift__c> myShifts = [
                SELECT Start_Time__c, End_Time__c, Session__r.Name
                FROM Shift__c
                WHERE User__c = :UserInfo.getUserId()
            ];

            for (Shift__c myShift : myShifts) {
                if (isTimeOverlap(
                    shift.Start_Time__c, shift.End_Time__c,
                    myShift.Start_Time__c, myShift.End_Time__c
                )) {
                    return new OverlapCheckResult(
                        true,
                        'This shift overlaps with: ' + myShift.Session__r.Name
                    );
                }
            }

            return new OverlapCheckResult(false, null);
        } catch (Exception e) {
            throw new AuraHandledException('Error checking overlap: ' + e.getMessage());
        }
    }

    private static String formatHHMM(Time t) {
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
               String.valueOf(t.minute()).leftPad(2, '0');
    }

    private static Boolean isTimeOverlap(Time start1, Time end1, Time start2, Time end2) {
        Long start1Ms = start1.hour() * 3600000 + start1.minute() * 60000;
        Long end1Ms = end1.hour() * 3600000 + end1.minute() * 60000;
        Long start2Ms = start2.hour() * 3600000 + start2.minute() * 60000;
        Long end2Ms = end2.hour() * 3600000 + end2.minute() * 60000;

        return (start1Ms < end2Ms) && (end1Ms > start2Ms);
    }

    public class SessionWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String location {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String sessionType {get; set;}
        @AuraEnabled public Integer minShifts {get; set;}
        @AuraEnabled public Integer maxShifts {get; set;}
        @AuraEnabled public Integer totalShifts {get; set;}
        @AuraEnabled public Integer claimedShifts {get; set;}
        @AuraEnabled public Integer availableShifts {get; set;}
        @AuraEnabled public Boolean needsStaff {get; set;}
        @AuraEnabled public Boolean isFull {get; set;}
        @AuraEnabled public Boolean canAddShift {get; set;}
        @AuraEnabled public String staffingStatus {get; set;}
        @AuraEnabled public List<ShiftDetail> shifts {get; set;}

        public SessionWrapper(Session__c session) {
            this.id = session.Id;
            this.name = session.Name;
            this.location = session.Location__c;
            this.description = session.Description__c;
            this.sessionType = session.Session_Type__r.Name;
            this.minShifts = session.Min_Shifts__c != null ? (Integer)session.Min_Shifts__c : 1;
            this.maxShifts = session.Max_Shifts__c != null ? (Integer)session.Max_Shifts__c : 5;

            this.shifts = new List<ShiftDetail>();
            Integer claimed = 0;
            for (Shift__c shift : session.Shifts__r) {
                this.shifts.add(new ShiftDetail(shift));
                if (shift.User__c != null) {
                    claimed++;
                }
            }

            this.totalShifts = session.Shifts__r.size();
            this.claimedShifts = claimed;
            this.availableShifts = this.totalShifts - claimed;
            this.needsStaff = claimed < this.minShifts;
            this.isFull = this.availableShifts == 0 && this.totalShifts >= this.maxShifts;
            this.canAddShift = this.totalShifts < this.maxShifts;

            if (claimed < this.minShifts) {
                this.staffingStatus = 'Needs Staff (' + claimed + '/' + this.minShifts + ')';
            } else if (this.availableShifts == 0 && this.totalShifts >= this.maxShifts) {
                this.staffingStatus = 'Fully Staffed';
            } else {
                this.staffingStatus = 'Open (' + claimed + '/' + this.totalShifts + ')';
            }
        }
    }

    public class ShiftDetail {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String startTime {get; set;}
        @AuraEnabled public String endTime {get; set;}
        @AuraEnabled public String assignedUserName {get; set;}
        @AuraEnabled public Boolean isClaimed {get; set;}
        @AuraEnabled public Boolean hasOverlap {get; set;}

        public ShiftDetail(Shift__c shift) {
            this.id = shift.Id;
            this.name = shift.Name;
            this.startTime = formatHHMM(shift.Start_Time__c);
            this.endTime = formatHHMM(shift.End_Time__c);
            this.assignedUserName = shift.User__r?.Name;
            this.isClaimed = shift.User__c != null;
            this.hasOverlap = shift.Has_Overlap__c;
        }
    }

    public class ShiftWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String startTime {get; set;}
        @AuraEnabled public String endTime {get; set;}
        @AuraEnabled public String sessionName {get; set;}
        @AuraEnabled public String sessionLocation {get; set;}
        @AuraEnabled public String sessionType {get; set;}
        @AuraEnabled public String sessionDescription {get; set;}
        @AuraEnabled public String assignedUserName {get; set;}
        @AuraEnabled public Boolean hasOverlap {get; set;}

        public ShiftWrapper(Shift__c shift) {
            this.id = shift.Id;
            this.name = shift.Name;
            this.startTime = formatHHMM(shift.Start_Time__c);
            this.endTime = formatHHMM(shift.End_Time__c);
            this.sessionName = shift.Session__r.Name;
            this.sessionLocation = shift.Session__r.Location__c;
            this.sessionType = shift.Session__r.Session_Type__r.Name;
            this.sessionDescription = shift.Session__r.Description__c;
            this.assignedUserName = shift.User__r?.Name;
            this.hasOverlap = shift.Has_Overlap__c;
        }
    }

    public class OverlapCheckResult {
        @AuraEnabled public Boolean hasOverlap {get; set;}
        @AuraEnabled public String message {get; set;}

        public OverlapCheckResult(Boolean hasOverlap, String message) {
            this.hasOverlap = hasOverlap;
            this.message = message;
        }
    }
}
