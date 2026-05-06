public with sharing class FreezeControlController {

    @AuraEnabled(cacheable=true)
    public static List<SessionTypeWrapper> getSessionTypesWithSessions() {
        List<Session_Type__c> types = [
            SELECT Id, Name, Is_Frozen__c,
                   (SELECT Id, Name, Is_Frozen__c, Location__c FROM Sessions__r ORDER BY Name)
            FROM Session_Type__c
            ORDER BY Name
        ];
        List<SessionTypeWrapper> wrappers = new List<SessionTypeWrapper>();
        for (Session_Type__c st : types) {
            wrappers.add(new SessionTypeWrapper(st));
        }
        return wrappers;
    }

    @AuraEnabled
    public static void toggleSessionTypeFreeze(Id sessionTypeId, Boolean isFrozen) {
        verifyAdmin();
        update new Session_Type__c(Id = sessionTypeId, Is_Frozen__c = isFrozen);
    }

    @AuraEnabled
    public static void toggleSessionFreeze(Id sessionId, Boolean isFrozen) {
        verifyAdmin();
        update new Session__c(Id = sessionId, Is_Frozen__c = isFrozen);
    }

    @AuraEnabled
    public static void bulkFreezeSessionsForType(Id sessionTypeId, Boolean isFrozen) {
        verifyAdmin();
        List<Session__c> sessions = [
            SELECT Id FROM Session__c WHERE Session_Type__c = :sessionTypeId
        ];
        for (Session__c s : sessions) {
            s.Is_Frozen__c = isFrozen;
        }
        update sessions;
    }

    private static void verifyAdmin() {
        if (!ShiftMarketplaceController.isCurrentUserAdmin()) {
            throw new AuraHandledException('Admin privileges required');
        }
    }

    public class SessionTypeWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Boolean isFrozen {get; set;}
        @AuraEnabled public List<SessionInfo> sessions {get; set;}

        public SessionTypeWrapper(Session_Type__c st) {
            this.id = st.Id;
            this.name = st.Name;
            this.isFrozen = st.Is_Frozen__c;
            this.sessions = new List<SessionInfo>();
            for (Session__c s : st.Sessions__r) {
                this.sessions.add(new SessionInfo(s));
            }
        }
    }

    public class SessionInfo {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Boolean isFrozen {get; set;}
        @AuraEnabled public String location {get; set;}

        public SessionInfo(Session__c s) {
            this.id = s.Id;
            this.name = s.Name;
            this.isFrozen = s.Is_Frozen__c;
            this.location = s.Location__c;
        }
    }
}
