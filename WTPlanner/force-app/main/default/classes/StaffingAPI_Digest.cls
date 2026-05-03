@RestResource(urlMapping='/staffing/digest')
global with sharing class StaffingAPI_Digest {
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        try {
            List<Session__c> sessions = [
                SELECT Id, Name, Location__c, Min_Shifts__c, Max_Shifts__c,
                       Session_Type__r.Name,
                       (SELECT Id, Start_Time__c, End_Time__c,
                               User__c, User__r.Name, User__r.Email, Has_Overlap__c
                        FROM Shifts__r
                        ORDER BY Start_Time__c)
                FROM Session__c
                ORDER BY Name
            ];

            Integer totalShifts = 0;
            Integer assignedCount = 0;
            Map<String, TypeStats> typeStatsMap = new Map<String, TypeStats>();
            List<Map<String, Object>> sessionsNeedingStaff = new List<Map<String, Object>>();
            Map<Id, LeaderEntry> leaderMap = new Map<Id, LeaderEntry>();
            Map<Id, UserDigest> userDigestMap = new Map<Id, UserDigest>();

            for (Session__c session : sessions) {
                String sessionType = session.Session_Type__r != null ? session.Session_Type__r.Name : 'Other';
                Integer minShifts = session.Min_Shifts__c != null ? (Integer)session.Min_Shifts__c : 1;
                Integer sessionTotal = session.Shifts__r.size();
                Integer sessionClaimed = 0;

                Map<String, Integer> claimedBySlot = new Map<String, Integer>();
                Map<String, Integer> totalBySlot = new Map<String, Integer>();

                for (Shift__c shift : session.Shifts__r) {
                    String slotKey = String.valueOf(shift.Start_Time__c) + '-' + String.valueOf(shift.End_Time__c);
                    totalBySlot.put(slotKey, (totalBySlot.containsKey(slotKey) ? totalBySlot.get(slotKey) : 0) + 1);

                    if (shift.User__c != null) {
                        sessionClaimed++;
                        claimedBySlot.put(slotKey, (claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0) + 1);

                        if (!leaderMap.containsKey(shift.User__c)) {
                            leaderMap.put(shift.User__c, new LeaderEntry(shift.User__r.Name));
                        }
                        leaderMap.get(shift.User__c).shiftCount++;

                        if (!userDigestMap.containsKey(shift.User__c)) {
                            userDigestMap.put(shift.User__c, new UserDigest(shift.User__r.Email, shift.User__r.Name));
                        }
                        userDigestMap.get(shift.User__c).shifts.add(new ShiftInfo(
                            session.Name, sessionType, formatTime(shift.Start_Time__c), formatTime(shift.End_Time__c)
                        ));
                    }
                }

                totalShifts += sessionTotal;
                assignedCount += sessionClaimed;

                if (!typeStatsMap.containsKey(sessionType)) {
                    typeStatsMap.put(sessionType, new TypeStats(sessionType));
                }
                TypeStats ts = typeStatsMap.get(sessionType);
                ts.totalShifts += sessionTotal;
                ts.assigned += sessionClaimed;

                Boolean needsStaff = false;
                for (String slotKey : totalBySlot.keySet()) {
                    Integer slotClaimed = claimedBySlot.containsKey(slotKey) ? claimedBySlot.get(slotKey) : 0;
                    if (slotClaimed < minShifts) {
                        needsStaff = true;
                        break;
                    }
                }

                if (needsStaff) {
                    sessionsNeedingStaff.add(new Map<String, Object>{
                        'name' => session.Name,
                        'sessionType' => sessionType,
                        'claimed' => sessionClaimed,
                        'minShifts' => minShifts,
                        'open' => sessionTotal - sessionClaimed
                    });
                }
            }

            List<Shift__c> overlappingShifts = [
                SELECT Id, User__c, User__r.Name, User__r.Email,
                       Start_Time__c, End_Time__c, Session__r.Name
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

            List<Map<String, String>> overlapList = new List<Map<String, String>>();
            for (Id userId : shiftsByUser.keySet()) {
                List<Shift__c> userShifts = shiftsByUser.get(userId);
                for (Integer i = 0; i < userShifts.size(); i++) {
                    for (Integer j = i + 1; j < userShifts.size(); j++) {
                        Shift__c s1 = userShifts[i];
                        Shift__c s2 = userShifts[j];
                        if (isTimeOverlap(s1.Start_Time__c, s1.End_Time__c, s2.Start_Time__c, s2.End_Time__c)) {
                            overlapList.add(new Map<String, String>{
                                'userName' => s1.User__r.Name,
                                'session1' => s1.Session__r.Name,
                                'time1' => formatTime(s1.Start_Time__c) + '-' + formatTime(s1.End_Time__c),
                                'session2' => s2.Session__r.Name,
                                'time2' => formatTime(s2.Start_Time__c) + '-' + formatTime(s2.End_Time__c)
                            });

                            if (userDigestMap.containsKey(userId)) {
                                userDigestMap.get(userId).overlaps.add(new Map<String, String>{
                                    'session1' => s1.Session__r.Name,
                                    'time1' => formatTime(s1.Start_Time__c) + '-' + formatTime(s1.End_Time__c),
                                    'session2' => s2.Session__r.Name,
                                    'time2' => formatTime(s2.Start_Time__c) + '-' + formatTime(s2.End_Time__c)
                                });
                            }
                        }
                    }
                }
            }

            Integer unassigned = totalShifts - assignedCount;
            Decimal fillRate = totalShifts > 0 ? ((Decimal)assignedCount / totalShifts * 100).setScale(1) : 0;

            List<TypeStats> bySessionType = typeStatsMap.values();
            bySessionType.sort();
            for (TypeStats ts : bySessionType) {
                ts.unassigned = ts.totalShifts - ts.assigned;
                ts.fillRate = ts.totalShifts > 0 ? ((Decimal)ts.assigned / ts.totalShifts * 100).setScale(1) : 0;
            }

            List<LeaderEntry> leaderboard = leaderMap.values();
            leaderboard.sort();
            for (Integer i = 0; i < leaderboard.size(); i++) {
                leaderboard[i].rank = i + 1;
            }

            Map<String, Object> result = new Map<String, Object>{
                'summary' => new Map<String, Object>{
                    'totalShifts' => totalShifts,
                    'assigned' => assignedCount,
                    'unassigned' => unassigned,
                    'fillRate' => fillRate,
                    'overlaps' => overlapList.size()
                },
                'bySessionType' => bySessionType,
                'sessionsNeedingStaff' => sessionsNeedingStaff,
                'leaderboard' => leaderboard,
                'overlaps' => overlapList,
                'userDigests' => userDigestMap.values()
            };

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(result));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() }
            ));
        }
    }

    private static String formatTime(Time t) {
        if (t == null) return '';
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' + String.valueOf(t.minute()).leftPad(2, '0');
    }

    private static Boolean isTimeOverlap(Time start1, Time end1, Time start2, Time end2) {
        Long s1 = start1.hour() * 3600000 + start1.minute() * 60000;
        Long e1 = end1.hour() * 3600000 + end1.minute() * 60000;
        Long s2 = start2.hour() * 3600000 + start2.minute() * 60000;
        Long e2 = end2.hour() * 3600000 + end2.minute() * 60000;
        return (s1 < e2) && (e1 > s2);
    }

    global class TypeStats implements Comparable {
        public String sessionType;
        public Integer totalShifts;
        public Integer assigned;
        public Integer unassigned;
        public Decimal fillRate;

        public TypeStats(String sessionType) {
            this.sessionType = sessionType;
            this.totalShifts = 0;
            this.assigned = 0;
            this.unassigned = 0;
            this.fillRate = 0;
        }

        public Integer compareTo(Object other) {
            return this.sessionType.compareTo(((TypeStats)other).sessionType);
        }
    }

    global class LeaderEntry implements Comparable {
        public Integer rank;
        public String userName;
        public Integer shiftCount;

        public LeaderEntry(String userName) {
            this.userName = userName;
            this.shiftCount = 0;
        }

        public Integer compareTo(Object other) {
            return ((LeaderEntry)other).shiftCount - this.shiftCount;
        }
    }

    global class UserDigest {
        public String email;
        public String userName;
        public List<ShiftInfo> shifts;
        public List<Map<String, String>> overlaps;

        public UserDigest(String email, String userName) {
            this.email = email;
            this.userName = userName;
            this.shifts = new List<ShiftInfo>();
            this.overlaps = new List<Map<String, String>>();
        }
    }

    global class ShiftInfo {
        public String sessionName;
        public String sessionType;
        public String startTime;
        public String endTime;

        public ShiftInfo(String sessionName, String sessionType, String startTime, String endTime) {
            this.sessionName = sessionName;
            this.sessionType = sessionType;
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }
}
