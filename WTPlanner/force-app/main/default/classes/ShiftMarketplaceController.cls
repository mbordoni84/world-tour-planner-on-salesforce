public with sharing class ShiftMarketplaceController {

    @AuraEnabled(cacheable=true)
    public static List<SessionWrapper> getSessionsNeedingStaff() {
        try {
            List<Session__c> sessions = [
                SELECT Id, Name, Location__c, Description__c,
                       Min_Shifts__c, Max_Shifts__c,
                       Is_Frozen__c, Session_Type__r.Is_Frozen__c,
                       Session_Type__r.Name,
                       session_owner__c, session_owner__r.Name,
                       (SELECT Id, Name, Start_Time__c, End_Time__c,
                               User__c, User__r.Name, Has_Overlap__c
                        FROM Shifts__r
                        ORDER BY Start_Time__c)
                FROM Session__c
                ORDER BY Name
            ];

            Boolean userIsAdmin = isCurrentUserAdmin();
            List<SessionWrapper> wrappers = new List<SessionWrapper>();
            for (Session__c session : sessions) {
                SessionWrapper wrapper = new SessionWrapper(session);
                if (!userIsAdmin && wrapper.isFrozen) {
                    continue;
                }
                wrappers.add(wrapper);
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sessions: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ShiftWrapper> getMyShifts() {
        return getShiftsForUser(UserInfo.getUserId());
    }

    @AuraEnabled
    public static List<ShiftWrapper> getShiftsForUser(String userId) {
        try {
            List<Shift__c> shifts = [
                SELECT Id, Name, Start_Time__c, End_Time__c,
                       User__c, User__r.Name, Has_Overlap__c,
                       Session__r.Name, Session__r.Location__c,
                       Session__r.Description__c,
                       Session__r.Is_Frozen__c,
                       Session__r.Session_Type__r.Name,
                       Session__r.Session_Type__r.Is_Frozen__c
                FROM Shift__c
                WHERE User__c = :userId
                ORDER BY Start_Time__c
            ];

            List<ShiftWrapper> wrappers = new List<ShiftWrapper>();
            for (Shift__c shift : shifts) {
                wrappers.add(new ShiftWrapper(shift));
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching shifts: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String claimShift(String shiftId) {
        try {
            Shift__c shift = [
                SELECT Id, User__c, Session__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            if (!isCurrentUserAdmin() && isSessionFrozen(shift.Session__c)) {
                AuraHandledException ex = new AuraHandledException('This session is currently frozen. You cannot claim shifts.');
                ex.setMessage('This session is currently frozen. You cannot claim shifts.');
                throw ex;
            }

            if (shift.User__c != null) {
                AuraHandledException ex = new AuraHandledException('This shift is already claimed');
                ex.setMessage('This shift is already claimed');
                throw ex;
            }

            // Detached patch update — we change User__c only. Building a
            // new SObject with just Id + the changed field avoids USER_MODE
            // checks against the master-detail Session__c field, which is
            // not user-updateable on Shift__c.
            Shift__c patch = new Shift__c(Id = shift.Id, User__c = UserInfo.getUserId());
            update as user patch;

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
            if (!isCurrentUserAdmin() && isSessionFrozen(sessionId)) {
                AuraHandledException ex = new AuraHandledException('This session is currently frozen. You cannot claim shifts.');
                ex.setMessage('This session is currently frozen. You cannot claim shifts.');
                throw ex;
            }

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
                insert as user newShift;
                return newShift.Id;
            }

            // See claimShift() for why we patch via a detached SObject.
            Shift__c patch = new Shift__c(Id = availableShifts[0].Id, User__c = UserInfo.getUserId());
            update as user patch;
            return patch.Id;
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
                SELECT Id, User__c, Session__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            if (!isCurrentUserAdmin() && isSessionFrozen(shift.Session__c)) {
                AuraHandledException ex = new AuraHandledException('This session is currently frozen. You cannot drop shifts.');
                ex.setMessage('This session is currently frozen. You cannot drop shifts.');
                throw ex;
            }

            if (shift.User__c != UserInfo.getUserId()) {
                AuraHandledException ex = new AuraHandledException('You can only drop your own shifts');
                ex.setMessage('You can only drop your own shifts');
                throw ex;
            }

            // See claimShift() for why we patch via a detached SObject.
            Shift__c patch = new Shift__c(Id = shift.Id, User__c = null);
            update as user patch;
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

    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserAdmin() {
        Schema.DescribeSObjectResult describeResult = Shift__c.SObjectType.getDescribe();
        return describeResult.isUpdateable() && describeResult.isDeletable();
    }

    @AuraEnabled(cacheable=true)
    public static List<UserOption> getEligibleUsers() {
        try {
            Set<Id> userIds = new Set<Id>();
            for (PermissionSetAssignment psa : [
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN ('Staffing_App_Admin', 'Staffing_App_Employee')
            ]) {
                userIds.add(psa.AssigneeId);
            }

            List<UserOption> options = new List<UserOption>();
            for (User u : [
                SELECT Id, Name
                FROM User
                WHERE Id IN :userIds AND IsActive = true
                ORDER BY Name
            ]) {
                options.add(new UserOption(u.Id, u.Name));
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching eligible users: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void adminAssignShift(String shiftId, String userId) {
        if (!isCurrentUserAdmin()) {
            AuraHandledException ex = new AuraHandledException('Admin privileges required');
            ex.setMessage('Admin privileges required');
            throw ex;
        }
        try {
            Shift__c shift = [
                SELECT Id, User__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];
            shift.User__c = userId;
            update shift;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning shift: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void adminUnassignShift(String shiftId) {
        if (!isCurrentUserAdmin()) {
            AuraHandledException ex = new AuraHandledException('Admin privileges required');
            ex.setMessage('Admin privileges required');
            throw ex;
        }
        try {
            Shift__c shift = [
                SELECT Id, User__c
                FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];
            shift.User__c = null;
            update shift;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error unassigning shift: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, List<String>> checkOverlapsForUsers(List<String> shiftIds) {
        try {
            List<Shift__c> targetShifts = [
                SELECT Id, Start_Time__c, End_Time__c
                FROM Shift__c
                WHERE Id IN :shiftIds
            ];

            Set<Id> eligibleUserIds = new Set<Id>();
            for (PermissionSetAssignment psa : [
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN ('Staffing_App_Admin', 'Staffing_App_Employee')
            ]) {
                eligibleUserIds.add(psa.AssigneeId);
            }

            List<Shift__c> allAssignedShifts = [
                SELECT Id, User__c, Start_Time__c, End_Time__c
                FROM Shift__c
                WHERE User__c IN :eligibleUserIds
                  AND User__c != null
            ];

            Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
            for (Shift__c s : allAssignedShifts) {
                if (!shiftsByUser.containsKey(s.User__c)) {
                    shiftsByUser.put(s.User__c, new List<Shift__c>());
                }
                shiftsByUser.get(s.User__c).add(s);
            }

            Map<String, List<String>> result = new Map<String, List<String>>();
            for (Shift__c target : targetShifts) {
                List<String> overlappingUserIds = new List<String>();
                for (Id uid : shiftsByUser.keySet()) {
                    for (Shift__c userShift : shiftsByUser.get(uid)) {
                        if (userShift.Id == target.Id) continue;
                        if (isTimeOverlap(
                            target.Start_Time__c, target.End_Time__c,
                            userShift.Start_Time__c, userShift.End_Time__c
                        )) {
                            overlappingUserIds.add(String.valueOf(uid));
                            break;
                        }
                    }
                }
                result.put(String.valueOf(target.Id), overlappingUserIds);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking overlaps: ' + e.getMessage());
        }
    }

    public static Boolean isSessionFrozen(Id sessionId) {
        Session__c session = [
            SELECT Is_Frozen__c, Session_Type__r.Is_Frozen__c
            FROM Session__c
            WHERE Id = :sessionId
            LIMIT 1
        ];
        return session.Is_Frozen__c || (session.Session_Type__r != null && session.Session_Type__r.Is_Frozen__c);
    }

    private static String formatHHMM(Time t) {
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
               String.valueOf(t.minute()).leftPad(2, '0');
    }

    @AuraEnabled(cacheable=false)
    public static List<SessionWrapper> getOwnedSessions() {
        return getOwnedSessionsForUser(UserInfo.getUserId());
    }

    @AuraEnabled(cacheable=false)
    public static List<SessionWrapper> getOwnedSessionsForUser(String userId) {
        try {
            List<Session__c> sessions = [
                SELECT Id, Name, Location__c, Description__c,
                       Min_Shifts__c, Max_Shifts__c,
                       Is_Frozen__c, Session_Type__r.Is_Frozen__c,
                       Session_Type__r.Name,
                       session_owner__c, session_owner__r.Name,
                       (SELECT Id, Name, Start_Time__c, End_Time__c,
                               User__c, User__r.Name, Has_Overlap__c
                        FROM Shifts__r
                        ORDER BY Start_Time__c)
                FROM Session__c
                WHERE session_owner__c = :userId
                ORDER BY Name
            ];
            List<SessionWrapper> wrappers = new List<SessionWrapper>();
            for (Session__c session : sessions) {
                wrappers.add(new SessionWrapper(session));
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching owned sessions: ' + e.getMessage());
        }
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
        @AuraEnabled public Boolean isFrozen {get; set;}
        @AuraEnabled public String staffingStatus {get; set;}
        @AuraEnabled public String sessionOwner {get; set;}
        @AuraEnabled public List<ShiftDetail> shifts {get; set;}

        public SessionWrapper(Session__c session) {
            this.id = session.Id;
            this.name = session.Name;
            this.location = session.Location__c;
            this.description = session.Description__c;
            this.sessionType = session.Session_Type__r.Name;
            this.sessionOwner = session.session_owner__r != null ? session.session_owner__r.Name : null;
            this.isFrozen = session.Is_Frozen__c ||
                (session.Session_Type__r != null && session.Session_Type__r.Is_Frozen__c);
            this.minShifts = session.Min_Shifts__c != null ? (Integer)session.Min_Shifts__c : 1;
            this.maxShifts = session.Max_Shifts__c != null ? (Integer)session.Max_Shifts__c : 5;

            this.shifts = new List<ShiftDetail>();
            Integer totalClaimed = 0;

            Map<String, Integer> claimedBySlot = new Map<String, Integer>();
            Map<String, Integer> totalBySlot = new Map<String, Integer>();

            for (Shift__c shift : session.Shifts__r) {
                this.shifts.add(new ShiftDetail(shift));
                String slotKey = String.valueOf(shift.Start_Time__c) + '-' + String.valueOf(shift.End_Time__c);
                totalBySlot.put(slotKey, (totalBySlot.containsKey(slotKey) ? totalBySlot.get(slotKey) : 0) + 1);
                if (shift.User__c != null) {
                    totalClaimed++;
                    claimedBySlot.put(slotKey, (claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0) + 1);
                }
            }

            this.totalShifts = session.Shifts__r.size();
            this.claimedShifts = totalClaimed;
            this.availableShifts = this.totalShifts - totalClaimed;

            Boolean anySlotNeedsStaff = false;
            Boolean allSlotsMinReached = !totalBySlot.isEmpty();
            Boolean allSlotsMaxReached = !totalBySlot.isEmpty();
            Integer worstClaimed = this.minShifts;

            for (String slotKey : totalBySlot.keySet()) {
                Integer slotClaimed = claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0;
                Integer slotTotal = totalBySlot.get(slotKey);
                if (slotClaimed < this.minShifts) {
                    anySlotNeedsStaff = true;
                    allSlotsMinReached = false;
                    worstClaimed = Math.min(worstClaimed, slotClaimed);
                }
                if (slotTotal - slotClaimed > 0) {
                    allSlotsMaxReached = false;
                }
            }

            Boolean allShiftsClaimed = (totalClaimed == this.totalShifts && this.totalShifts > 0);
            this.needsStaff = anySlotNeedsStaff;
            this.isFull = allShiftsClaimed;
            this.canAddShift = !allSlotsMaxReached;

            if (anySlotNeedsStaff) {
                this.staffingStatus = 'Needs Staff (' + worstClaimed + '/' + this.minShifts + ' min per slot)';
            } else if (allShiftsClaimed) {
                this.staffingStatus = 'Fully Staffed';
            } else {
                this.staffingStatus = 'Min Reached (' + totalClaimed + '/' + this.totalShifts + ' shifts)';
            }
        }
    }

    public class ShiftDetail {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String startTime {get; set;}
        @AuraEnabled public String endTime {get; set;}
        @AuraEnabled public String assignedUserId {get; set;}
        @AuraEnabled public String assignedUserName {get; set;}
        @AuraEnabled public Boolean isClaimed {get; set;}
        @AuraEnabled public Boolean hasOverlap {get; set;}

        public ShiftDetail(Shift__c shift) {
            this.id = shift.Id;
            this.name = shift.Name;
            this.startTime = formatHHMM(shift.Start_Time__c);
            this.endTime = formatHHMM(shift.End_Time__c);
            this.assignedUserId = shift.User__c;
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
        @AuraEnabled public Boolean isSessionFrozen {get; set;}

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
            this.isSessionFrozen = shift.Session__r.Is_Frozen__c ||
                (shift.Session__r.Session_Type__r != null && shift.Session__r.Session_Type__r.Is_Frozen__c);
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

    public class UserOption {
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public String label {get; set;}

        public UserOption(Id userId, String name) {
            this.value = String.valueOf(userId);
            this.label = name;
        }
    }
}
