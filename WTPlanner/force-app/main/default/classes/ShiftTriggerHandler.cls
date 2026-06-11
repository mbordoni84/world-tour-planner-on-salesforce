public with sharing class ShiftTriggerHandler {

    public void run() {
        if (Trigger.isAfter) {
            Set<Id> affectedUserIds = new Set<Id>();
            List<Shift__c> unassignedWithOverlap = new List<Shift__c>();
            List<ShiftChangeEvent> changeEvents = new List<ShiftChangeEvent>();

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

            if (Trigger.isUpdate) {
                Map<Id, Shift__c> oldMap = (Map<Id, Shift__c>)Trigger.oldMap;
                for (Shift__c shift : (List<Shift__c>)Trigger.new) {
                    Shift__c oldShift = oldMap.get(shift.Id);
                    if (shift.User__c != oldShift.User__c) {
                        if (oldShift.User__c != null) {
                            changeEvents.add(new ShiftChangeEvent(shift.Id, oldShift.User__c, 'removed'));
                        }
                        if (shift.User__c != null) {
                            changeEvents.add(new ShiftChangeEvent(shift.Id, shift.User__c, 'assigned'));
                        }
                    }
                }
            }

            if (Trigger.isInsert || Trigger.isUndelete) {
                for (Shift__c shift : (List<Shift__c>)Trigger.new) {
                    if (shift.User__c != null) {
                        changeEvents.add(new ShiftChangeEvent(shift.Id, shift.User__c, 'assigned'));
                    }
                }
            }

            if (Trigger.isDelete) {
                for (Shift__c shift : (List<Shift__c>)Trigger.old) {
                    if (shift.User__c != null) {
                        changeEvents.add(new ShiftChangeEvent(shift.Id, shift.User__c, 'removed'));
                    }
                }
            }

            if (!unassignedWithOverlap.isEmpty()) {
                update unassignedWithOverlap;
            }

            if (!affectedUserIds.isEmpty()) {
                detectOverlaps(affectedUserIds);
            }

            if (!changeEvents.isEmpty()) {
                notifySlack(changeEvents);
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

    @TestVisible
    private static Staffing_Setting__mdt slackSettingsOverride;

    @TestVisible
    private static Staffing_Setting__mdt getSlackSettings() {
        if (slackSettingsOverride != null) return slackSettingsOverride;
        List<Staffing_Setting__mdt> rows = [
            SELECT Slack_Notifications_Enabled__c, Slack_Shift_Webhook_URL__c, Slack_Owner_Webhook_URL__c
            FROM Staffing_Setting__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private void notifySlack(List<ShiftChangeEvent> events) {
        Staffing_Setting__mdt settings = getSlackSettings();
        if (settings == null || !settings.Slack_Notifications_Enabled__c) return;

        String webhookUrl = settings.Slack_Shift_Webhook_URL__c;
        if (String.isBlank(webhookUrl)) return;

        Set<Id> shiftIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for (ShiftChangeEvent evt : events) {
            shiftIds.add(evt.shiftId);
            userIds.add(evt.userId);
        }

        Map<Id, Shift__c> shiftMap = new Map<Id, Shift__c>([
            SELECT Id, Start_Time__c, End_Time__c,
                   Session__c, Session__r.Name,
                   Session__r.session_owner__c, Session__r.session_owner__r.Email
            FROM Shift__c
            WHERE Id IN :shiftIds
        ]);

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email, Name FROM User WHERE Id IN :userIds
        ]);

        // Collect session IDs for owner notifications
        Set<Id> sessionIds = new Set<Id>();
        for (Shift__c shift : shiftMap.values()) {
            if (shift.Session__c != null && shift.Session__r.session_owner__c != null) {
                sessionIds.add(shift.Session__c);
            }
        }

        // Query all sibling shifts for owner recap
        Map<Id, List<Map<String, Object>>> sessionShiftsMap = new Map<Id, List<Map<String, Object>>>();
        if (!sessionIds.isEmpty()) {
            for (Shift__c s : [
                SELECT Id, Start_Time__c, End_Time__c, User__r.Name, Session__c
                FROM Shift__c
                WHERE Session__c IN :sessionIds
                ORDER BY Start_Time__c
            ]) {
                if (!sessionShiftsMap.containsKey(s.Session__c)) {
                    sessionShiftsMap.put(s.Session__c, new List<Map<String, Object>>());
                }
                sessionShiftsMap.get(s.Session__c).add(new Map<String, Object>{
                    'startTime' => formatTime(s.Start_Time__c),
                    'endTime' => formatTime(s.End_Time__c),
                    'assignedUserName' => s.User__r != null ? s.User__r.Name : null
                });
            }
        }

        List<String> payloads = new List<String>();
        List<String> ownerPayloads = new List<String>();

        for (ShiftChangeEvent evt : events) {
            Shift__c shift = shiftMap.get(evt.shiftId);
            User u = userMap.get(evt.userId);
            if (shift == null || u == null) continue;

            String sessionName = shift.Session__r != null ? shift.Session__r.Name : 'Unknown';
            String shiftTime = formatTime(shift.Start_Time__c) + ' - ' + formatTime(shift.End_Time__c);

            // User notification (existing)
            payloads.add(JSON.serialize(new Map<String, Object>{
                'user_email' => u.Email,
                'session_name' => sessionName,
                'shift_time' => shiftTime,
                'change_type' => evt.changeType
            }));

            // Owner notification (new)
            if (shift.Session__r.session_owner__c != null
                && shift.Session__r.session_owner__c != evt.userId) {
                String ownerEmail = shift.Session__r.session_owner__r.Email;
                List<Map<String, Object>> sessionShifts = sessionShiftsMap.get(shift.Session__c);

                ownerPayloads.add(JSON.serialize(new Map<String, Object>{
                    'owner_email' => ownerEmail,
                    'session_name' => sessionName,
                    'changed_user_name' => u.Name,
                    'shift_time' => shiftTime,
                    'change_type' => evt.changeType,
                    'shifts' => JSON.serialize(sessionShifts != null ? sessionShifts : new List<Map<String, Object>>())
                }));
            }
        }

        if (!payloads.isEmpty()) {
            sendSlackNotifications(webhookUrl, payloads);
        }

        if (!ownerPayloads.isEmpty()) {
            String ownerWebhookUrl = settings.Slack_Owner_Webhook_URL__c;
            if (String.isNotBlank(ownerWebhookUrl)) {
                sendSlackNotifications(ownerWebhookUrl, ownerPayloads);
            }
        }
    }

    private String formatTime(Time t) {
        if (t == null) return '';
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' + String.valueOf(t.minute()).leftPad(2, '0');
    }

    @future(callout=true)
    public static void sendSlackNotifications(String webhookUrl, List<String> payloads) {
        for (String payload : payloads) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(webhookUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);
            req.setTimeout(10000);

            try {
                new Http().send(req);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Slack webhook failed: ' + e.getMessage());
            }
        }
    }

    private class ShiftChangeEvent {
        public Id shiftId;
        public Id userId;
        public String changeType;

        public ShiftChangeEvent(Id shiftId, Id userId, String changeType) {
            this.shiftId = shiftId;
            this.userId = userId;
            this.changeType = changeType;
        }
    }
}
