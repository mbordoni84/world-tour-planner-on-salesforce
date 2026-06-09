public with sharing class OverlapDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<OverlapWrapper> getOverlappingShifts() {
        try {
            Boolean isAdmin = hasModifyAllPermission();

            String query = 'SELECT Id, Name, User__c, User__r.Name, Has_Overlap__c, ' +
                          'Start_Time__c, End_Time__c, ' +
                          'Session__r.Name, Session__r.Location__c, Session__r.Session_Type__r.Name ' +
                          'FROM Shift__c ' +
                          'WHERE Has_Overlap__c = true AND User__c != null ';

            if (!isAdmin) {
                query += 'AND User__c = \'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\' ';
            }

            query += 'ORDER BY User__r.Name, Start_Time__c';

            List<Shift__c> shifts = Database.query(query, AccessLevel.USER_MODE);

            Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
            for (Shift__c shift : shifts) {
                if (!shiftsByUser.containsKey(shift.User__c)) {
                    shiftsByUser.put(shift.User__c, new List<Shift__c>());
                }
                shiftsByUser.get(shift.User__c).add(shift);
            }

            List<OverlapWrapper> wrappers = new List<OverlapWrapper>();

            for (Id userId : shiftsByUser.keySet()) {
                List<Shift__c> userShifts = shiftsByUser.get(userId);

                for (Integer i = 0; i < userShifts.size(); i++) {
                    for (Integer j = i + 1; j < userShifts.size(); j++) {
                        Shift__c shift1 = userShifts[i];
                        Shift__c shift2 = userShifts[j];

                        if (isTimeOverlap(
                            shift1.Start_Time__c, shift1.End_Time__c,
                            shift2.Start_Time__c, shift2.End_Time__c
                        )) {
                            wrappers.add(new OverlapWrapper(shift1, shift2));
                        }
                    }
                }
            }

            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching overlaps: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void dropShift(String shiftId) {
        try {
            Shift__c shift = [
                SELECT Id, User__c, Session__c FROM Shift__c
                WHERE Id = :shiftId
                LIMIT 1
            ];

            Boolean isAdmin = hasModifyAllPermission();
            if (!isAdmin && shift.User__c != UserInfo.getUserId()) {
                throw new AuraHandledException('You can only drop your own shifts');
            }

            if (!isAdmin && ShiftMarketplaceController.isSessionFrozen(shift.Session__c)) {
                AuraHandledException ex = new AuraHandledException('This session is currently frozen. You cannot drop shifts.');
                ex.setMessage('This session is currently frozen. You cannot drop shifts.');
                throw ex;
            }

            shift.User__c = null;
            update as user shift;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error dropping shift: ' + e.getMessage());
        }
    }

    private static Boolean hasModifyAllPermission() {
        Schema.DescribeSObjectResult describeResult = Shift__c.SObjectType.getDescribe();
        return describeResult.isUpdateable() && describeResult.isDeletable();
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

    public class OverlapWrapper {
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public String shift1Id {get; set;}
        @AuraEnabled public String shift1Name {get; set;}
        @AuraEnabled public String shift1Time {get; set;}
        @AuraEnabled public String shift1Session {get; set;}
        @AuraEnabled public String shift1SessionType {get; set;}
        @AuraEnabled public String shift2Id {get; set;}
        @AuraEnabled public String shift2Name {get; set;}
        @AuraEnabled public String shift2Time {get; set;}
        @AuraEnabled public String shift2Session {get; set;}
        @AuraEnabled public String shift2SessionType {get; set;}

        public OverlapWrapper(Shift__c shift1, Shift__c shift2) {
            this.userName = shift1.User__r.Name;
            this.shift1Id = shift1.Id;
            this.shift1Name = shift1.Name;
            this.shift1Time = formatHHMM(shift1.Start_Time__c) + ' - ' +
                             formatHHMM(shift1.End_Time__c);
            this.shift1Session = shift1.Session__r.Name;
            this.shift1SessionType = shift1.Session__r.Session_Type__r.Name;
            this.shift2Id = shift2.Id;
            this.shift2Name = shift2.Name;
            this.shift2Time = formatHHMM(shift2.Start_Time__c) + ' - ' +
                             formatHHMM(shift2.End_Time__c);
            this.shift2Session = shift2.Session__r.Name;
            this.shift2SessionType = shift2.Session__r.Session_Type__r.Name;
        }
    }
}
