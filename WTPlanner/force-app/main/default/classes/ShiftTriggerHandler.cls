public with sharing class ShiftTriggerHandler {

    public void run() {
        if (Trigger.isAfter) {
            Set<Id> affectedUserIds = new Set<Id>();
            List<Shift__c> unassignedWithOverlap = new List<Shift__c>();

            if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
                for (Shift__c shift : (List<Shift__c>)Trigger.new) {
                    if (shift.User__c != null) {
                        affectedUserIds.add(shift.User__c);
                    } else if (shift.Has_Overlap__c == true) {
                        unassignedWithOverlap.add(new Shift__c(Id = shift.Id, Has_Overlap__c = false));
                    }
                }
            }

            if (Trigger.isDelete || Trigger.isUpdate) {
                for (Shift__c shift : (List<Shift__c>)Trigger.old) {
                    if (shift.User__c != null) {
                        affectedUserIds.add(shift.User__c);
                    }
                }
            }

            if (!unassignedWithOverlap.isEmpty()) {
                update unassignedWithOverlap;
            }

            if (!affectedUserIds.isEmpty()) {
                detectOverlaps(affectedUserIds);
            }
        }
    }

    @TestVisible
    private void detectOverlaps(Set<Id> userIds) {
        List<Shift__c> allShifts = [
            SELECT Id, User__c, Has_Overlap__c,
                   Start_Time__c, End_Time__c
            FROM Shift__c
            WHERE User__c IN :userIds
            ORDER BY User__c, Start_Time__c
            LIMIT 200
        ];

        Map<Id, List<Shift__c>> shiftsByUser = new Map<Id, List<Shift__c>>();
        for (Shift__c shift : allShifts) {
            if (!shiftsByUser.containsKey(shift.User__c)) {
                shiftsByUser.put(shift.User__c, new List<Shift__c>());
            }
            shiftsByUser.get(shift.User__c).add(shift);
        }

        List<Shift__c> shiftsToUpdate = new List<Shift__c>();

        for (Id userId : shiftsByUser.keySet()) {
            List<Shift__c> userShifts = shiftsByUser.get(userId);
            Set<Id> overlappingIds = new Set<Id>();

            for (Integer i = 0; i < userShifts.size(); i++) {
                Shift__c shift1 = userShifts[i];
                for (Integer j = i + 1; j < userShifts.size(); j++) {
                    Shift__c shift2 = userShifts[j];

                    if (isTimeOverlap(
                        shift1.Start_Time__c, shift1.End_Time__c,
                        shift2.Start_Time__c, shift2.End_Time__c
                    )) {
                        overlappingIds.add(shift1.Id);
                        overlappingIds.add(shift2.Id);
                    }
                }
            }

            for (Shift__c shift : userShifts) {
                Boolean hasOverlap = overlappingIds.contains(shift.Id);
                if (shift.Has_Overlap__c != hasOverlap) {
                    shift.Has_Overlap__c = hasOverlap;
                    shiftsToUpdate.add(shift);
                }
            }
        }

        if (!shiftsToUpdate.isEmpty()) {
            update shiftsToUpdate;
        }
    }

    @TestVisible
    private Boolean isTimeOverlap(Time start1, Time end1, Time start2, Time end2) {
        Long start1Ms = start1.hour() * 3600000 + start1.minute() * 60000;
        Long end1Ms = end1.hour() * 3600000 + end1.minute() * 60000;
        Long start2Ms = start2.hour() * 3600000 + start2.minute() * 60000;
        Long end2Ms = end2.hour() * 3600000 + end2.minute() * 60000;

        return (start1Ms < end2Ms) && (end1Ms > start2Ms);
    }
}
