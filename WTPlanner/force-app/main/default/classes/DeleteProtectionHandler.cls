public with sharing class DeleteProtectionHandler {

    public static void preventEventDeletion(List<Event__c> events) {
        Set<Id> eventIds = new Set<Id>();
        for (Event__c evt : events) {
            eventIds.add(evt.Id);
        }

        Set<Id> blockedIds = new Set<Id>();
        for (Shift__c shift : [
            SELECT Session__r.Session_Type__r.Event__c
            FROM Shift__c
            WHERE Session__r.Session_Type__r.Event__c IN :eventIds
              AND User__c != null
        ]) {
            blockedIds.add(shift.Session__r.Session_Type__r.Event__c);
        }

        for (Event__c evt : events) {
            if (blockedIds.contains(evt.Id)) {
                evt.addError('Cannot delete: this event has sessions with assigned shifts. Remove all shift assignments first.');
            }
        }
    }

    public static void preventSessionTypeDeletion(List<Session_Type__c> sessionTypes) {
        Set<Id> stIds = new Set<Id>();
        for (Session_Type__c st : sessionTypes) {
            stIds.add(st.Id);
        }

        Set<Id> blockedIds = new Set<Id>();
        for (Shift__c shift : [
            SELECT Session__r.Session_Type__c
            FROM Shift__c
            WHERE Session__r.Session_Type__c IN :stIds
              AND User__c != null
        ]) {
            blockedIds.add(shift.Session__r.Session_Type__c);
        }

        for (Session_Type__c st : sessionTypes) {
            if (blockedIds.contains(st.Id)) {
                st.addError('Cannot delete: this session type has sessions with assigned shifts. Remove all shift assignments first.');
            }
        }
    }

    public static void preventSessionDeletion(List<Session__c> sessions) {
        Set<Id> sessionIds = new Set<Id>();
        for (Session__c s : sessions) {
            sessionIds.add(s.Id);
        }

        Set<Id> blockedIds = new Set<Id>();
        for (Shift__c shift : [
            SELECT Session__c
            FROM Shift__c
            WHERE Session__c IN :sessionIds
              AND User__c != null
        ]) {
            blockedIds.add(shift.Session__c);
        }

        for (Session__c s : sessions) {
            if (blockedIds.contains(s.Id)) {
                s.addError('Cannot delete: this session has assigned shifts. Remove all shift assignments first.');
            }
        }
    }
}
