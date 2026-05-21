List<Session__c> sessions = [SELECT Id FROM Session__c WHERE Event__c = null];
for (Session__c s : sessions) {
    s.Event__c = 'a2sJ9000000bxh6IAA';
}
update sessions;
System.debug('Updated ' + sessions.size() + ' sessions with Event__c');
