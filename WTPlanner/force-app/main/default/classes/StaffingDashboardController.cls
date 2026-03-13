public with sharing class StaffingDashboardController {

    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData() {
        try {
            // Query all sessions with their shifts
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

            // Build session staffing list and compute KPIs
            Integer totalShifts = 0;
            Integer assignedCount = 0;
            Integer overlapCount = 0;
            Set<String> sessionTypeSet = new Set<String>();
            Set<String> timeSlotSet = new Set<String>();
            List<SessionStaffing> sessionList = new List<SessionStaffing>();

            for (Session__c session : sessions) {
                SessionStaffing ss = new SessionStaffing(session);
                sessionList.add(ss);

                totalShifts += ss.totalShifts;
                assignedCount += ss.claimed;

                if (ss.sessionType != null) {
                    sessionTypeSet.add(ss.sessionType);
                }

                for (Shift__c shift : session.Shifts__r) {
                    if (shift.Has_Overlap__c && shift.User__c != null) {
                        overlapCount++;
                    }
                    String slot = formatTime(shift.Start_Time__c) + ' - ' + formatTime(shift.End_Time__c);
                    timeSlotSet.add(slot);
                }
            }

            Integer unassignedCount = totalShifts - assignedCount;
            Decimal fillRate = totalShifts > 0
                ? ((Decimal)assignedCount / totalShifts * 100).setScale(1)
                : 0;

            // Build overlap pairs
            List<Shift__c> overlappingShifts = [
                SELECT Id, Name, User__c, User__r.Name, Has_Overlap__c,
                       Start_Time__c, End_Time__c,
                       Session__r.Name, Session__r.Location__c
                FROM Shift__c
                WHERE Has_Overlap__c = true AND User__c != null
                ORDER BY User__r.Name, Start_Time__c
            ];

            Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
            for (Shift__c shift : overlappingShifts) {
                if (!shiftsByUser.containsKey(shift.User__c)) {
                    shiftsByUser.put(shift.User__c, new List<Shift__c>());
                }
                shiftsByUser.get(shift.User__c).add(shift);
            }

            List<OverlapPair> overlapPairs = new List<OverlapPair>();
            for (Id userId : shiftsByUser.keySet()) {
                List<Shift__c> userShifts = shiftsByUser.get(userId);
                for (Integer i = 0; i < userShifts.size(); i++) {
                    for (Integer j = i + 1; j < userShifts.size(); j++) {
                        if (isTimeOverlap(
                            userShifts[i].Start_Time__c, userShifts[i].End_Time__c,
                            userShifts[j].Start_Time__c, userShifts[j].End_Time__c
                        )) {
                            overlapPairs.add(new OverlapPair(userShifts[i], userShifts[j]));
                        }
                    }
                }
            }

            // Build result
            DashboardData data = new DashboardData();
            data.summary = new DashboardSummary(totalShifts, assignedCount, unassignedCount, overlapPairs.size(), fillRate);
            data.sessions = sessionList;
            data.overlaps = overlapPairs;

            List<String> sortedTypes = new List<String>(sessionTypeSet);
            sortedTypes.sort();
            data.sessionTypes = sortedTypes;

            List<String> sortedSlots = new List<String>(timeSlotSet);
            sortedSlots.sort();
            data.timeSlots = sortedSlots;

            // Build leaderboard — count shifts per user
            Map<Id, LeaderboardEntry> leaderMap = new Map<Id, LeaderboardEntry>();
            for (Session__c session : sessions) {
                for (Shift__c shift : session.Shifts__r) {
                    if (shift.User__c != null) {
                        if (!leaderMap.containsKey(shift.User__c)) {
                            leaderMap.put(shift.User__c, new LeaderboardEntry(shift.User__r.Name));
                        }
                        leaderMap.get(shift.User__c).shiftCount++;
                    }
                }
            }
            List<LeaderboardEntry> leaderList = leaderMap.values();
            leaderList.sort();
            // Assign ranks
            for (Integer i = 0; i < leaderList.size(); i++) {
                leaderList[i].rank = i + 1;
            }
            data.leaderboard = leaderList;

            return data;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching dashboard data: ' + e.getMessage());
        }
    }

    private static String formatTime(Time t) {
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

    public class DashboardData {
        @AuraEnabled public DashboardSummary summary {get; set;}
        @AuraEnabled public List<SessionStaffing> sessions {get; set;}
        @AuraEnabled public List<OverlapPair> overlaps {get; set;}
        @AuraEnabled public List<String> sessionTypes {get; set;}
        @AuraEnabled public List<String> timeSlots {get; set;}
        @AuraEnabled public List<LeaderboardEntry> leaderboard {get; set;}
    }

    public class DashboardSummary {
        @AuraEnabled public Integer totalShifts {get; set;}
        @AuraEnabled public Integer assigned {get; set;}
        @AuraEnabled public Integer unassigned {get; set;}
        @AuraEnabled public Integer overlaps {get; set;}
        @AuraEnabled public Decimal fillRate {get; set;}

        public DashboardSummary(Integer totalShifts, Integer assigned, Integer unassigned, Integer overlaps, Decimal fillRate) {
            this.totalShifts = totalShifts;
            this.assigned = assigned;
            this.unassigned = unassigned;
            this.overlaps = overlaps;
            this.fillRate = fillRate;
        }
    }

    public class SessionStaffing {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String sessionType {get; set;}
        @AuraEnabled public String location {get; set;}
        @AuraEnabled public String timeRange {get; set;}
        @AuraEnabled public Integer claimed {get; set;}
        @AuraEnabled public Integer minShifts {get; set;}
        @AuraEnabled public Integer maxShifts {get; set;}
        @AuraEnabled public Integer totalShifts {get; set;}
        @AuraEnabled public String status {get; set;}

        public SessionStaffing(Session__c session) {
            this.id = session.Id;
            this.name = session.Name;
            this.sessionType = session.Session_Type__r.Name;
            this.location = session.Location__c;
            this.minShifts = session.Min_Shifts__c != null ? (Integer)session.Min_Shifts__c : 1;
            this.maxShifts = session.Max_Shifts__c != null ? (Integer)session.Max_Shifts__c : 5;
            this.totalShifts = session.Shifts__r.size();

            Integer claimedCount = 0;
            Time earliest = null;
            Time latest = null;
            for (Shift__c shift : session.Shifts__r) {
                if (shift.User__c != null) {
                    claimedCount++;
                }
                if (earliest == null || shift.Start_Time__c < earliest) {
                    earliest = shift.Start_Time__c;
                }
                if (latest == null || shift.End_Time__c > latest) {
                    latest = shift.End_Time__c;
                }
            }
            this.claimed = claimedCount;

            if (earliest != null && latest != null) {
                this.timeRange = formatTimeStatic(earliest) + ' - ' + formatTimeStatic(latest);
            } else {
                this.timeRange = 'No shifts';
            }

            if (claimedCount < this.minShifts) {
                this.status = 'Needs Staff';
            } else if (claimedCount >= this.maxShifts) {
                this.status = 'Fully Staffed';
            } else {
                this.status = 'Min Reached';
            }
        }

        private String formatTimeStatic(Time t) {
            return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
                   String.valueOf(t.minute()).leftPad(2, '0');
        }
    }

    public class LeaderboardEntry implements Comparable {
        @AuraEnabled public Integer rank {get; set;}
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public Integer shiftCount {get; set;}

        public LeaderboardEntry(String userName) {
            this.userName = userName;
            this.shiftCount = 0;
        }

        public Integer compareTo(Object other) {
            LeaderboardEntry o = (LeaderboardEntry)other;
            return o.shiftCount - this.shiftCount; // descending
        }
    }

    public class OverlapPair {
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public String session1 {get; set;}
        @AuraEnabled public String time1 {get; set;}
        @AuraEnabled public String session2 {get; set;}
        @AuraEnabled public String time2 {get; set;}

        public OverlapPair(Shift__c shift1, Shift__c shift2) {
            this.userName = shift1.User__r.Name;
            this.session1 = shift1.Session__r.Name;
            this.time1 = String.valueOf(shift1.Start_Time__c) + ' - ' + String.valueOf(shift1.End_Time__c);
            this.session2 = shift2.Session__r.Name;
            this.time2 = String.valueOf(shift2.Start_Time__c) + ' - ' + String.valueOf(shift2.End_Time__c);
        }
    }
}
