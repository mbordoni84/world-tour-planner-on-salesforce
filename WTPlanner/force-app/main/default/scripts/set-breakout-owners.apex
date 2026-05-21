User ansidei = [SELECT Id FROM User WHERE Name = 'Annalisa Ansidei' AND IsActive = true LIMIT 1];
User rufolo  = [SELECT Id FROM User WHERE Name = 'Paola Rufolo'    AND IsActive = true LIMIT 1];

List<Session__c> sessions = [
    SELECT Id, Location__c
    FROM Session__c
    WHERE Session_Type__r.Name = 'Breakout'
];

List<Session__c> toUpdate = new List<Session__c>();
for (Session__c s : sessions) {
    toUpdate.add(new Session__c(
        Id = s.Id,
        session_owner__c = s.Location__c == 'Breakout B4' ? rufolo.Id : ansidei.Id
    ));
}
update toUpdate;
System.debug('Aggiornate ' + toUpdate.size() + ' breakout session');
