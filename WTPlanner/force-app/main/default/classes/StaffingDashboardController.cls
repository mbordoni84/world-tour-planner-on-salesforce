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
            Decimal totalHours = 0;
            Decimal assignedHours = 0;
            Set<String> sessionTypeSet = new Set<String>();
            Set<String> timeSlotSet = new Set<String>();
            Set<Id> uniqueStaffedSet = new Set<Id>();
            List<SessionStaffing> sessionList = new List<SessionStaffing>();

            // session type KPI accumulators
            Map<String, SessionTypeKpi> kpiByType = new Map<String, SessionTypeKpi>();

            Integer mandatoryUnassigned = 0;

            for (Session__c session : sessions) {
                SessionStaffing ss = new SessionStaffing(session);
                sessionList.add(ss);

                totalShifts += ss.totalShifts;
                assignedCount += ss.claimed;
                if (ss.claimed < ss.minShifts) {
                    mandatoryUnassigned += (ss.minShifts - ss.claimed);
                }

                String typeName = ss.sessionType != null ? ss.sessionType : 'Unknown';
                if (ss.sessionType != null) {
                    sessionTypeSet.add(ss.sessionType);
                }

                if (!kpiByType.containsKey(typeName)) {
                    SessionTypeKpi k = new SessionTypeKpi();
                    k.name = typeName;
                    k.totalShifts = 0;
                    k.assignedShifts = 0;
                    k.totalHours = 0;
                    k.assignedHours = 0;
                    k.sessionCount = 0;
                    k.minReachedCount = 0;
                    kpiByType.put(typeName, k);
                }
                SessionTypeKpi typeKpi = kpiByType.get(typeName);
                typeKpi.totalShifts += ss.totalShifts;
                typeKpi.assignedShifts += ss.claimed;
                typeKpi.sessionCount++;
                if (ss.isMinReached) typeKpi.minReachedCount++;

                for (Shift__c shift : session.Shifts__r) {
                    if (shift.Has_Overlap__c && shift.User__c != null) {
                        overlapCount++;
                    }
                    String slot = formatTime(shift.Start_Time__c) + ' - ' + formatTime(shift.End_Time__c);
                    timeSlotSet.add(slot);

                    Decimal shiftHours = shiftDurationHours(shift.Start_Time__c, shift.End_Time__c);
                    totalHours += shiftHours;
                    typeKpi.totalHours += shiftHours;
                    if (shift.User__c != null) {
                        assignedHours += shiftHours;
                        typeKpi.assignedHours += shiftHours;
                        uniqueStaffedSet.add(shift.User__c);
                    }
                }
            }

            // Finalize session type KPIs
            List<SessionTypeKpi> sessionTypeKpiList = new List<SessionTypeKpi>();
            for (SessionTypeKpi k : kpiByType.values()) {
                k.fillRate = k.totalShifts > 0
                    ? ((Decimal)k.assignedShifts / k.totalShifts * 100).setScale(1)
                    : 0;
                k.totalHours = k.totalHours.setScale(1);
                k.assignedHours = k.assignedHours.setScale(1);
                k.remainingHours = (k.totalHours - k.assignedHours).setScale(1);
                k.allMinReached = (k.sessionCount > 0 && k.minReachedCount == k.sessionCount);
                sessionTypeKpiList.add(k);
            }
            sessionTypeKpiList.sort(new SessionTypeKpiComparator());

            Integer unassignedCount = mandatoryUnassigned;
            Decimal fillRate = totalShifts > 0
                ? ((Decimal)assignedCount / totalShifts * 100).setScale(1)
                : 0;
            totalHours = totalHours.setScale(1);
            assignedHours = assignedHours.setScale(1);

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
            data.summary = new DashboardSummary(totalShifts, assignedCount, unassignedCount, overlapPairs.size(), fillRate, totalHours, assignedHours, uniqueStaffedSet.size());
            data.sessionTypeKpis = sessionTypeKpiList;
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
                        leaderMap.get(shift.User__c).totalHours += shiftDurationHours(shift.Start_Time__c, shift.End_Time__c);
                    }
                }
            }
            List<LeaderboardEntry> leaderList = leaderMap.values();
            leaderList.sort();
            // Assign ranks
            for (Integer i = 0; i < leaderList.size(); i++) {
                leaderList[i].rank = i + 1;
                leaderList[i].totalHours = leaderList[i].totalHours.setScale(1);
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
        @AuraEnabled public List<SessionTypeKpi> sessionTypeKpis {get; set;}
    }

    public class DashboardSummary {
        @AuraEnabled public Integer totalShifts {get; set;}
        @AuraEnabled public Integer assigned {get; set;}
        @AuraEnabled public Integer unassigned {get; set;}
        @AuraEnabled public Integer overlaps {get; set;}
        @AuraEnabled public Decimal fillRate {get; set;}
        @AuraEnabled public Decimal totalHours {get; set;}
        @AuraEnabled public Decimal assignedHours {get; set;}
        @AuraEnabled public Integer uniqueStaffed {get; set;}

        public DashboardSummary(Integer totalShifts, Integer assigned, Integer unassigned, Integer overlaps, Decimal fillRate, Decimal totalHours, Decimal assignedHours, Integer uniqueStaffed) {
            this.totalShifts = totalShifts;
            this.assigned = assigned;
            this.unassigned = unassigned;
            this.overlaps = overlaps;
            this.fillRate = fillRate;
            this.totalHours = totalHours;
            this.assignedHours = assignedHours;
            this.uniqueStaffed = uniqueStaffed;
        }
    }

    public class SessionTypeKpi {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Integer totalShifts {get; set;}
        @AuraEnabled public Integer assignedShifts {get; set;}
        @AuraEnabled public Decimal fillRate {get; set;}
        @AuraEnabled public Decimal totalHours {get; set;}
        @AuraEnabled public Decimal assignedHours {get; set;}
        @AuraEnabled public Decimal remainingHours {get; set;}
        @AuraEnabled public Boolean allMinReached {get; set;}
        @AuraEnabled public Integer sessionCount {get; set;}
        @AuraEnabled public Integer minReachedCount {get; set;}
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
        @AuraEnabled public Boolean isMinReached {get; set;}
        @AuraEnabled public Integer earliestStartMins {get; set;}
        @AuraEnabled public Integer latestEndMins {get; set;}

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

            Map<String, Integer> claimedBySlot = new Map<String, Integer>();
            Map<String, Integer> totalBySlot = new Map<String, Integer>();

            for (Shift__c shift : session.Shifts__r) {
                String slotKey = String.valueOf(shift.Start_Time__c) + '-' + String.valueOf(shift.End_Time__c);
                totalBySlot.put(slotKey, (totalBySlot.containsKey(slotKey) ? totalBySlot.get(slotKey) : 0) + 1);
                if (shift.User__c != null) {
                    claimedCount++;
                    claimedBySlot.put(slotKey, (claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0) + 1);
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
                this.earliestStartMins = earliest.hour() * 60 + earliest.minute();
                this.latestEndMins = latest.hour() * 60 + latest.minute();
            } else {
                this.timeRange = 'No shifts';
                this.earliestStartMins = 0;
                this.latestEndMins = 0;
            }

            Boolean anySlotNeedsStaff = false;
            Boolean allSlotsMinReached = !totalBySlot.isEmpty();
            for (String slotKey : totalBySlot.keySet()) {
                Integer slotClaimed = claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0;
                if (slotClaimed < this.minShifts) {
                    anySlotNeedsStaff = true;
                    allSlotsMinReached = false;
                }
            }

            Boolean allShiftsClaimed = (this.claimed == this.totalShifts && this.totalShifts > 0);
            this.isMinReached = !anySlotNeedsStaff;
            if (anySlotNeedsStaff) {
                this.status = 'Needs Staff';
            } else if (allShiftsClaimed) {
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
        @AuraEnabled public Decimal totalHours {get; set;}

        public LeaderboardEntry(String userName) {
            this.userName = userName;
            this.shiftCount = 0;
            this.totalHours = 0;
        }

        public Integer compareTo(Object other) {
            LeaderboardEntry o = (LeaderboardEntry)other;
            if (o.totalHours > this.totalHours) return 1;
            if (o.totalHours < this.totalHours) return -1;
            return 0;
        }
    }

    private static String formatTimeVal(Time t) {
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
               String.valueOf(t.minute()).leftPad(2, '0');
    }

    private static Decimal shiftDurationHours(Time startTime, Time endTime) {
        if (startTime == null || endTime == null) return 0;
        Long startMs = startTime.hour() * 3600000L + startTime.minute() * 60000L;
        Long endMs = endTime.hour() * 3600000L + endTime.minute() * 60000L;
        Long diffMs = endMs - startMs;
        if (diffMs <= 0) return 0;
        return Decimal.valueOf(diffMs) / 3600000;
    }

    private class SessionTypeKpiComparator implements Comparator<SessionTypeKpi> {
        public Integer compare(SessionTypeKpi a, SessionTypeKpi b) {
            return a.name.compareTo(b.name);
        }
    }

    @AuraEnabled(cacheable=false)
    public static StaffOverviewData getStaffOverview() {
        try {
            List<Shift__c> shifts = [
                SELECT User__c, User__r.Name, User__r.Email,
                       Start_Time__c, End_Time__c
                FROM Shift__c
                WHERE User__c != null
                ORDER BY User__r.Name
            ];

            Map<Id, StaffMember> memberMap = new Map<Id, StaffMember>();
            for (Shift__c s : shifts) {
                if (!memberMap.containsKey(s.User__c)) {
                    memberMap.put(s.User__c, new StaffMember(s.User__c, s.User__r.Name, s.User__r.Email));
                }
                StaffMember m = memberMap.get(s.User__c);
                m.shiftCount++;
                m.totalHours += shiftDurationHours(s.Start_Time__c, s.End_Time__c);
            }

            List<StaffMember> members = memberMap.values();
            members.sort(new StaffMemberComparator());

            // Owner session count per user
            Map<Id, Integer> ownerSessionCount = new Map<Id, Integer>();
            Set<String> ownerEmailSet = new Set<String>();
            for (Session__c s : [
                SELECT session_owner__c, session_owner__r.Email
                FROM Session__c
                WHERE session_owner__c != null
            ]) {
                Integer cnt = ownerSessionCount.containsKey(s.session_owner__c)
                    ? ownerSessionCount.get(s.session_owner__c) + 1 : 1;
                ownerSessionCount.put(s.session_owner__c, cnt);
                if (String.isNotBlank(s.session_owner__r.Email)) {
                    ownerEmailSet.add(s.session_owner__r.Email);
                }
            }
            List<String> ownerEmails = new List<String>(ownerEmailSet);
            ownerEmails.sort();

            Decimal totalHoursSum = 0;
            List<String> emails = new List<String>();
            for (StaffMember m : members) {
                m.totalHours = m.totalHours.setScale(1);
                m.isUnderFourHours = m.totalHours < 4;
                totalHoursSum += m.totalHours;
                if (String.isNotBlank(m.email)) {
                    emails.add(m.email);
                }
                m.ownerSessionCount = ownerSessionCount.containsKey(m.userId)
                    ? ownerSessionCount.get(m.userId) : 0;
            }

            StaffOverviewData result = new StaffOverviewData();

            result.totalStaffed = members.size();
            result.avgHours = members.size() > 0
                ? (totalHoursSum / members.size()).setScale(1)
                : 0;
            result.members = members;
            result.emailList = String.join(emails, ',');
            result.ownerEmailList = String.join(ownerEmails, ',');
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching staff overview: ' + e.getMessage());
        }
    }

    public class StaffOverviewData {
        @AuraEnabled public Integer totalStaffed {get; set;}
        @AuraEnabled public Decimal avgHours {get; set;}
        @AuraEnabled public List<StaffMember> members {get; set;}
        @AuraEnabled public String emailList {get; set;}
        @AuraEnabled public String ownerEmailList {get; set;}
    }

    public class StaffMember {
        @AuraEnabled public String userId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public Decimal totalHours {get; set;}
        @AuraEnabled public Integer shiftCount {get; set;}
        @AuraEnabled public Boolean isUnderFourHours {get; set;}
        @AuraEnabled public Integer ownerSessionCount {get; set;}

        public StaffMember(String userId, String name, String email) {
            this.userId = userId;
            this.name = name;
            this.email = email;
            this.totalHours = 0;
            this.shiftCount = 0;
            this.isUnderFourHours = false;
            this.ownerSessionCount = 0;
        }
    }

    private class StaffMemberComparator implements Comparator<StaffMember> {
        public Integer compare(StaffMember a, StaffMember b) {
            return a.name.compareTo(b.name);
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
            this.time1 = formatTimeVal(shift1.Start_Time__c) + ' - ' + formatTimeVal(shift1.End_Time__c);
            this.session2 = shift2.Session__r.Name;
            this.time2 = formatTimeVal(shift2.Start_Time__c) + ' - ' + formatTimeVal(shift2.End_Time__c);
        }
    }
}
